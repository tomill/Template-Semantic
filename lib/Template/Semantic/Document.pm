package Template::Semantic::Document;
use strict;
use warnings;
use Carp;
use HTML::Selector::XPath;
use Scalar::Util qw/blessed/;
use XML::LibXML;

use overload q{""} => sub { shift->as_string }, fallback => 1;

sub new {
    my $class = shift;
    my $self  = bless { @_ }, $class;

    my $source = $self->{source};
    # quick hack for xhtml default ns
    $source =~ s{(<html[^>]+?)xmlns="http://www\.w3\.org/1999/xhtml"}{
        $self->{xmlns_hacked} = 1;
        $1 . 'xmlns=""';
    }e;
    
    $self->{dom} = $self->{engine}{parser}->parse_string($source);
    $self;
}

sub process {
    my ($self, $vars) = @_;
    $self->_query($self->{dom}, $vars);
    $self;
}

sub as_string {
    my ($self) = @_;
    if ($self->{source} =~ /^<\?xml/) {
        return $self->{dom}->serialize(1);
    }
    else { # for skip <?xml declaration.
           # I know html_parse_string->toString, but it doesn't do I want.
        my $r = "";
        if (my $dtd = $self->{dom}->internalSubset) {
            $r = $dtd->serialize . "\n";
        }
        if (my $root = $self->{dom}->documentElement) {
            $r .= $root->serialize(1);
            $r =~ s/\n*$/\n/;
            
            if ($self->{xmlns_hacked}) {
                $r =~ s{(<html[^>]+?)xmlns=""}{$1xmlns="http://www.w3.org/1999/xhtml"};
            }
        }
        return $r;
    }
}

sub _exp_to_xpath {
    my ($self, $exp) = @_;
    return unless $exp;
    
    my $xpath;
    if ($exp =~ m{^/}) {
        $xpath = $exp;
    } elsif ($exp =~ m{^id\(}) {
        $xpath = $exp;
        $xpath =~ s{^id\((.+?)\)}{//\*\[\@id=$1\]}g; # id() hack
    } else { # css selector
        my ($elem, $attr) = $exp =~ m{(.*?)/?(@[^/]+)?$}; # extends @attr syntax
        if ($elem) {
            $xpath = HTML::Selector::XPath::selector_to_xpath($elem);
            $xpath .= "/$attr" if $attr;
        } elsif ($attr) {
            $xpath = "//$attr";
        }
    }
    $xpath;
}

sub _query {
    my ($self, $context, $vars) = @_;
    croak "\$vars must be hashref." if ref($vars) ne 'HASH';
    
    for my $exp (keys %$vars) {
        my $xpath = $self->_exp_to_xpath($exp) or next;
        my $nodes = $context->findnodes($xpath);
        $self->_assign_value($nodes, delete $vars->{$exp});
    }
}

sub _assign_value {
    my ($self, $nodes, $value) = @_;
    my $value_type = ref $value;
    
    if (not defined $value) { # => delete
        for my $node (@$nodes) {
            $node->unbindNode;
        }
    }
    
    elsif ($value_type eq 'HASH') { # => sub query
        for my $node (@$nodes) {
            if ($node->isa('XML::LibXML::Attr')) {
                croak "can't assign hashref to \@attr.";
                last;
            }
            
            my $fixed_value = { };
            my $prefix_xpath = '/' . $node->nodeName;
            for my $exp (keys %$value) {
                $fixed_value->{ $prefix_xpath . $self->_exp_to_xpath($exp) } = delete $value->{$exp};
            }
             
            my $parted = $self->_to_node($node->serialize);
            $self->_query($parted, $fixed_value);
            $node->replaceNode($parted);
        }
    }
    
    elsif ($value_type eq 'ARRAY' and ref($value->[0]) eq 'HASH') { # => sub query loop
        for my $node (@$nodes) {
            if ($node->isa('XML::LibXML::Attr')) {
                croak "can't assign arrayref of hashrefs to \@attr.";
                last;
            }
            
            my $container = XML::LibXML::DocumentFragment->new;
            my $joint;
            for my $v (@$value) {
                next if ref($v) ne 'HASH';

                my $tmpl = $self->_to_node($node->serialize);
                $self->_query($tmpl, $v);
                $container->addChild($joint->cloneNode) if $joint;
                $container->addChild($tmpl);
                
                if (not defined $joint) { # 2nd item
                    my $p = $node->previousSibling;
                    $joint = ($p and $p->serialize =~ /^(\W+)$/s) ? $p : "";
                }
            }
            $node->replaceNode($container);
        }
    }
    
    elsif ($value_type eq 'ARRAY') { # => value, filter, filter, ...
        my ($value, @filters) = @$value;
        for my $filter (@filters) {
            if (not ref($filter) and my $f = $self->{engine}{filter}{$filter}) {
                $filter = \&$f;
            }
        }
        
        for my $node (@$nodes) {
            $self->_assign_value([$node], $value);
            
            for my $filter (@filters) {
                $self->_assign_value([$node], $filter);
            }
        }
    }
    elsif ($value_type eq 'CODE') { # => callback
        for my $node (@$nodes) {
            local $_ = $self->_serialize_inner($node);
            my $ret = eval { $value->($node) };
            if ($@) {
                croak "callback error: $@";
            } else {
                $self->_assign_value([$node], $ret);
            }
        }
    }
    elsif (blessed($value) and $value->can('filter')) { # => Text::Pipe like filter
        for my $node (@$nodes) {
            my $ret = $value->filter( $self->_serialize_inner($node) );
            $self->_assign_value([$node], $ret);
        }
    }
    
    elsif (blessed($value) and $value->isa('XML::LibXML::Node')) { # => as LibXML object
        for my $node (@$nodes) {
            $node->removeChildNodes;
            $node->addChild( $value->cloneNode(1) );
        }
    }
    elsif (blessed($value) and $value->isa('Template::Semantic::Document')) { # => insert result
        for my $node (@$nodes) {
            $node->removeChildNodes;
            $node->addChild( $_->cloneNode(1) ) for $value->{dom}->childNodes;
        }
    }
    elsif ($value_type eq 'SCALAR') { # => as HTML/XML
        my $root = $self->_to_node("<root>${$value}</root>");
        for my $node (@$nodes) {
            $node->removeChildNodes;
            $node->addChild( $_->cloneNode(1) ) for $root->childNodes;
        }
    }
    else { # => text or unknown(stringify)
        my $value = XML::LibXML::Text->new("$value");
        for my $node (@$nodes) {
            $node->removeChildNodes;
            $node->addChild($value->cloneNode);
        }
    }
}

sub _to_node {
     my ($self, $xmlpart) = @_;
     $self->{engine}{parser}->parse_string($xmlpart)->documentElement;
}

sub _serialize_inner {
    my ($self, $node) = @_;
    my $inner = "";
    if ($node->isa('XML::LibXML::Attr')) {
        $inner = $node->value;
    } else {
        $inner .= $_->serialize for $node->childNodes;
    }
    $inner;
}

1;
__END__

=head1 NAME

Template::Semantic::Document - Template::Semantic Result object

=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 METHODS

=over 4

=item ->process( \%vars )

=item ->as_string

=back

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=cut
