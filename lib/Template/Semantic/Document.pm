package Template::Semantic::Document;
use strict;
use warnings;

use Carp;
use HTML::Selector::XPath;
use XML::LibXML;

use overload q{""} => sub { shift->as_string }, fallback => 1;

sub new {
    my $class = shift;
    my $self  = bless {
        source => "",
        parser => "",
        dom    => "",
        @_
    }, $class;

    my $source = $self->{source};
    
    # quick hack for xhtml default ns
    $source =~ s{(<html[^>]+?)xmlns="http://www\.w3\.org/1999/xhtml"}{
        $self->{xmlns_hacked} = 1;
        $1 . 'xmlns=""';
    }e;
    
    $self->{dom} = $self->{parser}->parse_string($source);
    $self;
}

sub process {
    my ($self, $vars) = @_;
    $self->_query($self->{dom}, $vars);
    $self;
}

sub as_string {
    my ($self) = @_;
    my $r = "";
    if ($self->{source} =~ /^<\?xml/) {
        $r = $self->{dom}->serialize(1);
    }
    else { # for skip <?xml declaration
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
    }
    $r;
}

sub _exp_to_xpath {
    my ($self, $exp) = @_;
    my $xpath;
    if (not $exp) {
        return;
    } elsif ($exp =~ m{^/}) {
        $xpath = $exp;
    } elsif ($exp =~ m{^id\(}) {
        $xpath = $exp;
        $xpath =~ s{^id\((.+?)\)}{//\*\[\@id=$1\]}g; # id() hack
    } else { # css selector
        my ($elem, $attr) = $exp =~ m{(.*?)/?(@[^/]+)?$}; # "@attr" syntax is this module original.
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

sub _get_node_from {
     my ($self, $xmlpart) = @_;
     $self->{parser}->parse_string($xmlpart)->documentElement;
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
            
            my $fixed = { };
            my $prefix_xpath = '/' . $node->nodeName;
            for my $exp (keys %$value) {
                $fixed->{ $prefix_xpath . $self->_exp_to_xpath($exp) } = delete $value->{$exp};
            }
             
            my $part = $self->_get_node_from($node->serialize);
            $self->_query($part, $fixed);
            $node->replaceNode($part);
        }
    }
    elsif ($value_type eq 'ARRAY' and ref($value->[0]) eq 'HASH') { # => sub query loop
        for my $node (@$nodes) {
            if ($node->isa('XML::LibXML::Attr')) {
                croak "can't assign arrayref of hashrefs to \@attr.";
                last;
            }
            
            my $container = XML::LibXML::DocumentFragment->new;
            for my $v (@$value) {
                my $tmpl = $self->_get_node_from($node->serialize);
                $self->_query($tmpl, $v);
                $container->addChild($tmpl);
            }
            $node->replaceNode($container);
        }
    }
    elsif ($value_type eq 'ARRAY') { # => value, filter, filter, ...
        my ($value, @filters) = @$value;
        for my $filter (@filters) {
            if ($filter and not ref($filter)) {
                $filter = "Template::Semantic::Filter::$filter" unless $filter =~ /::/;
                $filter = \&$filter;
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
            local $_ = $node->textContent;
            my $ret = eval { $value->($node) };
            if ($@) {
                croak "callback error: $@";
            } else {
                $self->_assign_value([$node], $ret);
            }
        }
    }
    elsif ($value_type eq 'SCALAR') { # => as HTML/XML
        my $root = $self->_get_node_from("<root>${$value}</root>");
        for my $node (@$nodes) {
            $node->removeChildNodes;
            $node->addChild( $_->cloneNode(1) ) for $root->childNodes;
        }
    }
    elsif ($value_type and $value->isa('XML::LibXML::Node')) { # => as LibXML object
        for my $node (@$nodes) {
            $node->removeChildNodes;
            $node->addChild( $value->cloneNode(1) );
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

1;
