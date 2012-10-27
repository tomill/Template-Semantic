package Template::Semantic;
use strict;
use warnings;
use 5.008000;
our $VERSION = '0.09';
use Carp;
use Scalar::Util qw/blessed/;
use XML::LibXML;
use Template::Semantic::Document;
use Template::Semantic::Filter;

sub new {
    my ($class, %opt) = @_;
    my $self  = bless { }, $class;
    
    $self->{parser} = delete $opt{parser};
    $self->{parser} ||= do {
        my $parser = XML::LibXML->new;
        $parser->no_network(1); # faster
        $parser->recover(2);    # = recover_silently(1) = no warnings
        $parser->$_($opt{$_}) for keys %opt;
        $parser;
    };
    
    for (@Template::Semantic::Filter::EXPORT_OK) {
        $self->define_filter($_ => \&{'Template::Semantic::Filter::' . $_});
    }
    
    $self;
}

sub define_filter {
    my ($self, $name, $code) = @_;
    $self->{filter}{$name} ||= $code;
}

sub call_filter {
    my ($self, $name) = @_;
    $name ||= "";
    my $filter = ref($self) ? $self->{filter}{$name}
                            : Template::Semantic::Filter->can($name);
    $filter or croak "Filter $name not defined.";
}

sub process {
    my $self = ref $_[0] ? shift : shift->new;
    my ($template, $vars) = @_;
    
    my $source;
    if (ref($template) eq 'SCALAR') {
        $source = $$template;
    } elsif (ref($template) eq 'GLOB'
        or blessed($template) && $template->isa('GLOB')) {
        $source = do { local $/; <$template> };
    } else {
        open(my $fh, '<', $template) or croak $!;
        $source = do { local $/; <$fh> };
    }
    
    my $doc = Template::Semantic::Document->new(
        engine => $self,
        source => $source || "",
    );
    $doc->process($vars || {});
}

1;
__END__

=head1 NAME

Template::Semantic - Use pure XHTML/XML as a template

=head1 SYNOPSIS

  use Template::Semantic;
  
  print Template::Semantic->process('template.html', {
      'title, h1' => 'Naoki Tomita',
      'ul.urls li' => [
          { 'a' => 'Profile & Contacts', 'a@href' => 'http://e8y.net/', },
          { 'a' => 'Twitter',            'a@href' => 'http://twitter.com/tomita/', },
      ],
  });

template.html

  <html>
      <head><title>person name</title></head>
      <body>
          <h1>person name</h1>
          <ul class="urls">
              <li><a href="#">his page</a></li>
          </ul>
      </body>
  </html>

output:

  <html>
      <head><title>Naoki Tomita</title></head>
      <body>
          <h1>Naoki Tomita</h1>
          <ul class="urls">
              <li><a href="http://e8y.net/">Profile &amp; Contacts</a></li>
              <li><a href="http://twitter.com/tomita/">Twitter</a></li>
          </ul>
      </body>
  </html>

=head1 DESCRIPTION

Template::Semantic is a template engine for XHTML/XML based on L<XML::LibXML>
that doesn't use any template syntax. This module takes pure XHTML/XML as a template,
and uses XPath or CSS selectors to assign values.

=head1 METHODS

=over 4

=item $ts = Template::Semantic->new( %options )

Constructs a new C<Template::Semantic> object.

  my $ts = Template::Semantic->new(
      ...
  );
  my $res = $ts->process(...);

If you do not want to change the options from the defaults, you may skip
C<new()> and call C<process()> directly:

  my $res = Template::Semantic->process(...);

Set %options if you want to change parser options:

=over 4

=item * parser => $your_libxml_parser

Set if you want to replace XML parser. It should be L<XML::LibXML> based.

  my $ts = Template::Semantic->new(
      parser => My::LibXML->new,
  );

=item * (others)

All other parameters are applied to the XML parser as method calls
(C<< $parser->$key($value) >>). Template::Semantic uses this configuration
by default:

  no_newwork => 1  # faster
  recover    => 2  # "no warnings" style

See L<XML::LibXML::Parser/PARSER OPTIONS> for details.

  # "use strict;" style
  my $ts = Template::Semantic->new( recover => 0 );
  
  # "use warnings;" style
  my $ts = Template::Semantic->new( recover => 1 );

=back

=item $res = $ts->process($filename, \%vars)

=item $res = $ts->process(\$text, \%vars)

=item $res = $ts->process(FH, \%vars)

Process a template and return a L<Template::Semantic::Document> object.

The first parameter is the input template, which may take one of several forms:

  # filename
  my $res = Template::Semantic->process('template.html', $vars);
  
  # text reference
  my $res = Template::Semantic->process(\'<html><body>foo</body></html>', $vars);
  
  # file handle, GLOB
  my $res = Template::Semantic->process($fh, $vars);
  my $res = Template::Semantic->process(\*DATA, $vars);

The second parameter is a value set to bind the template. $vars should be a
hash-ref of selectors and corresponding values.  See the L</SELECTOR> and
L</VALUE TYPE> sections below.  For example:

  {
    '.foo'    => 'hello',
    '//title' => 'This is a title',
  }

=item $ts->define_filter($filter_name, \&code)

=item $ts->call_filter($filter_name)

See the L</Filter> section.

=back


=head1 SELECTOR

Use XPath expression or CSS selector as a selector. If the expression
doesn't look like XPath, it is considered CSS selector and converted
into XPath internally.

  print Template::Semantic->process($template, {
      
      # XPath sample that indicate <tag>
      '/html/body/h2[2]' => ...,
      '//title | //h1'   => ...,
      '//img[@id="foo"]' => ...,
      'id("foo")'        => ...,
      
      # XPath sample that indicate @attr
      '//a[@id="foo"]/@href'              => ...,
      '//meta[@name="keywords"]/@content' => ...,
      
      # CSS selector sample that indicate <tag>
      'title'         => ...,
      '#foo'          => ...,
      '.foo span.bar' => ...,
      
      # CSS selector sample that indicate @attr
      'img#foo@src'     => ...,
      'span.bar a@href' => ...,
      '@alt, @title'    => ...,
  
  });

Template::Semantic allows some selector syntax that is different
from usual XPath for your convenience.

1. You can use xpath C<'//div'> without using L<XML::LibXML::XPathContext>
even if your template has default namespace (C<< <html xmlns="..."> >>).

2. You can use C<'id("foo")'> function to find element with C<id="foo">
instead of C<xml:id="foo"> without DTD. Note: use C<'//*[@xml:id="foo"]'>
if your template uses C<xml:id="foo">.

3. You can C<'@attr'> syntax with CSS selector that specifies the attribute.
This is original syntax of this module.


=head1 VALUE TYPE

=head2 Basics

=over 4

=item * selector => $text

I<Scalar:> Replace the inner content with this as Text.

  $ts->process($template, {
      'h1' => 'foo & bar',   # <h1></h1> =>
                             # <h1>foo &amp; bar</h1>
       
      '.foo@href' => '/foo', # <a href="#" class="foo">bar</a> =>
                             # <a href="/foo" class="foo">bar</a>
  });

=item * selector => \$html

I<Scalar-ref:> Replace the inner content with this as fragment XML/HTML.

  $ts->process($template, {
      'h1' => \'<a href="#">foo</a>bar', # <h1></h1> =>
                                         # <h1><a href="#">foo</a>bar</h1>
  });

=item * selector => undef

I<undef:> Delete the element/attirbute that the selector indicates.

  $ts->process($template, {
      'h1'            => undef, # <div><h1>foo</h1>bar</div> =>
                                # <div>bar</div>
      
      'div.foo@class' => undef, # <div class="foo">foo</div> =>
                                # <div>foo</div>
  });

=item * selector => XML::LibXML::Node

Replace the inner content by the node. XML::LibXML::Attr isn't supported.

  $ts->process($template, {
      'h1' => do { XML::LibXML::Text->new('foo') },
  });

=item * selector => Template::Semantic::Document

Replace the inner content by another C<process()>-ed result.

  $ts->process('wrapper.html', {
      'div#content' => $ts->process('inner.html', ...),
  });

=item * selector => { 'selector' => $value, ... }

I<Hash-ref:> Sub query of the part.
 
  $ts->process($template, {
      # All <a> tag *in <div class="foo">* disappears
      'div.foo' => {
          'a' => undef,
      },
      
      # same as above
      'div.foo a' => undef,
      
      # xpath '.' = current node (itself)
      'a#bar' => {
          '.'       => 'foobar',
          './@href' => 'foo.html',
      },
      
      # same as above
      'a#bar'       => 'foobar',
      'a#bar/@href' => 'foo.html',
  });

=back


=head2 Loop

=over 4

=item * selector => [ \%row, \%row, ... ]

I<Array-ref of Hash-refs:> Loop the part as template. Each item
of the array-ref should be hash-ref.

  $ts->process(\*DATA, {
      'table.list tr' => [
          { 'th' => 'aaa', 'td' => '001' },
          { 'th' => 'bbb', 'td' => '002' },
          { 'th' => 'ccc', 'td' => '003' },
      ],
  });
  
  __DATA__
  <table class="list">
      <tr>
          <th></th>
          <td></td>
      </tr>
  </table>

Output:

  <table class="list">
      <tr>
          <th>aaa</th>
          <td>001</td>
      </tr>
      <tr>
          <th>bbb</th>
          <td>002</td>
      </tr>
      <tr>
          <th>ccc</th>
          <td>003</td>
      </tr>
  </table>

=back


=head2 Callback

=over 4

=item * selector => \&foo

I<Code-ref:> Callback subroutine. The callback receives

  $_    => innerHTML
  $_[0] => XML::LibXML::Node object (X::L::Element, X::L::Attr, ...)

Its return value is handled per this list of value types
(scalar to replace content, undef to delete, etc.).

  $ts->process($template, {
      # samples
      'h1' => sub { "bar" }, # <h1>foo</h1> => <h1>bar</h1>
      'h1' => sub { undef }, # <h1>foo</h1> => disappears
      
      # sample: use $_
      'h1' => sub { uc },  # <h1>foo</h1> => <h1>FOO</h1>
      
      # sample: use $_[0]
      'h1' => sub {
          my $node = shift;
          $node->nodeName; # <h1>foo</h1> => <h1>h1</h1>
      },
  });

=back


=head2 Filter

=over 4

=item * selector => [ $value, filter, filter, ... ]

I<Array-ref of Scalars:> Value and filters. Filters may be

A) Callback subroutine (code reference)

B) Defined filter name

C) Object like L<Text::Pipe> (C<< it->can('filter') >>)

  $ts->process($template, {
      'h1' => [ 'foo', sub { uc }, sub { "$_!" } ], # => <h1>FOO!</h1>
      'h2' => [ ' foo ', 'trim', sub { "$_!" } ],   # => <h2>FOO!</h2>
      'h3' => [ 'foo', PIPE('UppercaseFirst') ],    # => <h3>Foo</h3>
  });

=over 4

=item Defined basic filters

Some basic filters included. See L<Template::Semantic::Filter>.

=item $ts->define_filter($filter_name, \&code)

You can define your own filters using C<define_filter()>.

  use Text::Markdown qw/markdown/;
  $ts->define_filter(markdown => sub { \ markdown($_) })
  $ts->process($template, {
      'div.content' => [ $text, 'markdown' ],
  });

=item $code = $ts->call_filter($filter_name)

Accessor to defined filter.

  $ts->process($template, {
      'div.entry'      => ...,
      'div.entry-more' => ...,
  })->process({
      'div.entry, div.entry-more' => $ts->call_filter('markdown'),
  });

=back

=back


=head1 SEE ALSO

L<Template::Semantic::Cookbook>

L<Template::Semantic::Document>

L<XML::LibXML>, L<HTML::Selector::XPath>

I got a lot of ideas from L<Template>, L<Template::Refine>,
L<Web::Scraper>. thanks!

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

Feedback, patches, POD English check are always welcome!

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
