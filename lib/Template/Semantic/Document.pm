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

sub dom { $_[0]->{dom} }

sub process {
    my ($self, $vars) = @_;
    $self->_query($self->{dom}, $vars);
    $self;
}

sub as_string {
    my ($self, %opt) = @_;
    
    $opt{is_xhtml} = 1 unless defined $opt{is_xhtml};

    if ($self->{source} =~ /^<\?xml/) {
        return $self->{dom}->serialize(1);
    }
    else { # for skip <?xml declaration.
        my $r = "";
        if (my $dtd = $self->{dom}->internalSubset) {
            $r = $dtd->serialize . "\n";
        } elsif($opt{is_xhtml}) {
            $self->{dom}->createInternalSubset(
                'html',
                '-//W3C//DTD XHTML 1.0 Transitional//EN',
                'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd',
            );
            $self->{dom_hacked}++;
        }

        if (my $root = $self->{dom}->documentElement) {
            $r .= $root->serialize;
            $r =~ s/\n*$/\n/;
            
            if ($self->{xmlns_hacked}) {
                $r =~ s{(<html[^>]+?)xmlns=""}{$1xmlns="http://www.w3.org/1999/xhtml"};
            }
        }
        if ($self->{dom_hacked}) {
            $self->{dom}->removeInternalSubset;
            $self->{dom_hacked} = 0;
        }
        
        return $r;
    }
}

my $element_with_attr_regex = qr{
    ^
    \s*
    (
        \@[^@]+? |
        (?:
            (?: [^"]+? | .+?"[^"]+".+? )
            (?: \@[^@]+? )?
        )
    )
    \s*
    (?: , | $ )
}x;

sub _exp_to_xpath {
    my ($self, $exp) = @_;
    return unless $exp;
    
    my $xpath;
    if ($exp =~ m{^(?:/|\.(?:/|$))}) {
        $xpath = $exp;
    } elsif ($exp =~ m{^id\(}) {
        $xpath = $exp;
        $xpath =~ s{^id\((.+?)\)}{//\*\[\@id=$1\]}g; # id() hack
    } else {
        # css selector extends @attr syntax
        my @x;
        while ($exp =~ s/$element_with_attr_regex//) {
            my $e = $1;
            my ($elem, $attr) = $e =~ m{(.*?)/?(@[^/@]+)?$};
            my $x;
            if ($elem) {
                my $x = HTML::Selector::XPath::selector_to_xpath($elem);
                   $x .= "/$attr" if $attr;
                push @x, $x;
            } elsif ($attr) {
                push @x, "//$attr";
            }
        }
        $xpath = join " | ", @x;
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
            if (not $node->isa('XML::LibXML::Element')) {
                croak "Can't assign hashref to " . ref($node);
            }
             
            my $parted = $self->_to_node($node->serialize);
            $self->_query($parted, $value);
            $node->replaceNode($parted);
        }
    }
    
    elsif ($value_type eq 'ARRAY' and ref($value->[0]) eq 'HASH') { # => sub query loop
        for my $node (@$nodes) {
            if (not $node->isa('XML::LibXML::Element')) {
                croak "Can't assign loop list to " . ref($node);
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
            if (not ref $filter) {
                $filter = $self->{engine}->call_filter($filter);
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
                croak "Callback error: $@";
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
    
    elsif (blessed($value) and $value->isa('Template::Semantic::Document')) { # => insert result
        for my $node (@$nodes) {
            if (not $node->isa('XML::LibXML::Element')) {
                croak "Can't assign Template::Semantic::Document to " . ref($node);
            }
            $self->_replace_node($node, $value->{dom}->childNodes);
        }
    }
    elsif (blessed($value) and $value->isa('XML::LibXML::Node')) { # => as LibXML object
        if ($value->isa('XML::LibXML::Attr')) {
            croak "Can't assign XML::LibXML::Attr to any element";
        }
        for my $node (@$nodes) {
            $self->_replace_node($node, $value);
        }
    }
    elsif ($value_type eq 'SCALAR') { # => as HTML/XML
        my $root = $self->_to_node("<root>${$value}</root>");
        for my $node (@$nodes) {
            $self->_replace_node($node, $root->childNodes);
        }
    }
    else { # => text or unknown(stringify)
        my $value = XML::LibXML::Text->new("$value");
        for my $node (@$nodes) {
            $self->_replace_node($node, $value);
        }
    }
}

sub _to_node {
     my ($self, $xmlpart) = @_;
     $self->{engine}{parser}->parse_string($xmlpart)->documentElement;
}

sub _replace_node {
    my ($self, $node, @replace) = @_;
    
    if ($node->isa('XML::LibXML::Element')) {
        $node->removeChildNodes;
        $node->addChild($_->cloneNode(1)) for @replace;
    }
    elsif ($node->isa('XML::LibXML::Attr')) {
        $node->setValue(join "", map { $_->textContent } @replace);
    }
    elsif ($node->isa('XML::LibXML::Comment')
        or $node->isa('XML::LibXML::CDATASection')) {
        $node->setData(join "",  map { $_->nodeValue || $_->serialize } @replace);
    }
    elsif ($node->isa('XML::LibXML::Text')) {
        $node->setData(join "",  map { $_->textContent } @replace);
    }
}

sub _serialize_inner {
    my ($self, $node) = @_;
    my $inner = "";
    if ($node->isa('XML::LibXML::Attr')) {
        $inner = $node->value;
    }
    elsif ($node->isa('XML::LibXML::Comment')
        or $node->isa('XML::LibXML::CDATASection')) {
        $inner = $node->data;
    }
    elsif ($node->isa('XML::LibXML::Text')) {
        $inner = $node->serialize;
    }
    else {
        $inner .= $_->serialize for $node->childNodes;
    }
    $inner;
}

1;
__END__

=head1 NAME

Template::Semantic::Document - Template::Semantic Result object

=head1 SYNOPSIS

  my $out = Template::Semantic->process('template.html', {
      'title, h1' => 'foo',
  });
  
  my $out = Template::Semantic->process('template.html', {
      '.foo, .bar' => 'baz',
      '.mee@class' => 'moo',
  })->process({
      '#boo@src' => 'grr',
      '#yea .ye' => 'yoo',
  })->process({
      '.foo' => sub { uc },
      '.bar' => sub { lc },
  });
  
  print $out;
  print $out->as_string; # same as avobe

=head1 METHODS

=over 4

=item $out = $out->process( \%vars )

Process again to the result and returns L<Template::Semantic::Document>
object again. So you can chain C<< ->process(...)->process(...) >>.

=item "$out" (stringify)

Calls C<as_string()> internally.

=item $html = $out->as_string( %options )

Returns the result as XHTML/XML.

=over 4

=item * is_xhtml => [1|0]

Default value is true. Even if DTD is not defined in the template, outputs as XHTML.
When sets C<is_xhtml> false, skip this effect.

  my $out = $ts->process(\<<END);
  <div>
      <img src="foo" />
      <br />
      <textarea></textarea>
  </div>
  END
  ;
  
  print $out;
  
  <div>
      <img src="foo" />
      <br />
      <textarea></textarea>
  </div>
  
  print $out->as_string(is_xhtml => 0);
  
  <div>
      <img src="foo"/>
      <br/>
      <textarea/>
  </div>

=back

=item $dom = $out->dom()

  my $out  = Template::Semantic->process($template, ...);
  my $dom  = $out->dom;
  my $root = $dom->documentElement; # get root element

Gets the result as L<XML::LibXML::Document>.

=back

=head1 SEE ALSO

L<Template::Semantic>

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=cut
