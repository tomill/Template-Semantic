package Template::Semantic;
use strict;
use warnings;
use 5.008000;
our $VERSION = '0.01';
use Carp;
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
    $self->{filter}{$name} or croak "Filter $name not defined.";
}

sub process {
    my $self = ref $_[0] ? shift : shift->new;
    my ($template, $vars) = @_;
    
    my $source;
    if (ref($template) eq 'SCALAR') {
        $source = $$template;
    } elsif (ref $template) {
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
          {
              'a' => 'Homepage >',
              'a@href' => 'http://e8y.net/',
          },
          {
              'a' => 'Twitter >',
              'a@href' => 'http://twitter.com/tomita/',
          },
      ],
  });

template:

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
              <li><a href="http://e8y.net/">Homepage &gt;</a></li>
              <li><a href="http://twitter.com/tomita/">Twitter &gt;</a></li>
          </ul>
      </body>
  </html>

=head1 DESCRIPTION

Template::Semantic is a template engine for XHTML/XML based on L<XML::LibXML>
that doesn't use any template syntax. This module takes pure XHTML/XML as a template,
and uses XPath or CSS selector to assign value.

B<This is beta release. Your feedback is welcome.>

=head1 METHODS

=over 4

=item $ts = Template::Semantic->new( %options )

Constructs a new C<Template::Semantic> object.

  my $ts = Template::Semantic->new;
  my $out = $ts->process(...);

Template::Semantic uses L<XML::LibXML> parser as follows by default.

  my $parser = XML::LibXML->new;
  $parser->no_newwork(1); # faster
  $parser->recover(2);    # = recover_silently(1) = no warnings

If you may not change this, call C<process()> directly, skip C<new()>.

  my $out = Template::Semantic->process(...);

Set %options if you want to change parser options:

=over 4

=item * C<parser>

Set if you want to replace XML parser. It should be L<XML::LibXML> based.

  my $ts = Template::Semantic->new(
      parser => $your_libxml_parser,
  );

=item * (others)

All other parameters except C<"parser"> are passed to XML parser like
C<< $parser->$key($value) >>. See L<XML::LibXML::Parser> for details.

  my $ts = Template::Semantic->new(
      recover => 1,
      expand_xinclude => 1,
  );

=back

=item $out = $ts->process($filename, \%vars)

=item $out = $ts->process(\$text, \%vars)

=item $out = $ts->process(FH, \%vars)

Process a template and returns L<Template::Semantic::Document> object.

The 1st parameter is the input template that can take these types:

  # filename
  my $out = Template::Semantic->process('template.html', $vars);
  
  # text reference
  my $out = Template::Semantic->process(\'<html><body>foo</body></html>', $vars);
  
  # file handle
  my $out = Template::Semantic->process($fh, $vars);
  my $out = Template::Semantic->process(\*DATA, $vars);

The 2nd parameter is a value set to bind the template. This should be hash-ref
like { 'selector' => $value, 'selector' => $value, ... }. See below
L</SELECTOR> and L</VALUE TYPE> section.

=item $ts->define_filter($filter_name, \&code)

=item $ts->call_filter($filter_name)

See L</Filter> section.

=back


=head1 SELECTOR

Use XPath expression or CSS selector as a selector.

  print Template::Semantic->process($template, {
      
      # XPath sample that indicate tag:
      '/html/body/h2[2]' => ...,
      '//title | //h1'   => ...,
      '//img[@id="foo"]' => ...,
      'id("foo")'        => ...,
      
      # XPath sample that indicate attribute:
      '//a[@id="foo"]/@href'              => ...,
      '//meta[@name="keywords"]/@content' => ...,
      
      # CSS selector sample that indicate tag:
      'title'         => ...,
      '.foo span.bar' => ...,
      '#foo'          => ...,
      
      # CSS selector sample that indicate attribute:
      'img#foo@src'     => ...,
      'span.bar a@href' => ...,
  
  });

Note 1: CSS selector is converted to XPath internally. You can use '@attr'
expression to indicate attribute in this module unlike CSS format.

Note 2: You can use 'id()' function in XHTML (with C<< <html xmlns="..." >>)
without using L<XML::LibXML::XPathContext>. This module sets C<xmlns="">
namespace declarations automatically if template like a XHTML.


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

I<Scalar-ref:> Replace the inner content with this as flagment XML/HTML.

  $ts->process($template, {
      'h1' => \'<a href="#">foo</a>bar', # <h1></h1> =>
                                         # <h1><a href="#">foo</a>bar</h1>
  });

=item * selector => undef

I<undef:> Delete the element/attirbute that the selector indicates.

  $ts->process($template, {
      'h1'            => undef, # <div><h1></h1>foo</div> =>
                                # <div>foo</div>
      
      'div.foo@class' => undef, # <div class="foo">foo</div> =>
                                # <div>foo</div>
  });

=item * selector => XML::LibXML::Node

Replace the inner content by the node. Note: XML::LibXML::Attr isn't supported.

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
      'div.foo' => {
          'a' => undef, # All <a> tag *in <div class="foo">* disappears
      },
   
      'div.foo a' => undef, # same as above
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
          <td></td>
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

I<Code-ref:> Callback subroutine. Subroutine can user C<$_> as inner HTML
or first argument as L<XML::LibXML::Node> object. The value that subroutine
returned is allocated by value type.

  $ts->process($template, {
      # samples
      'h1' => sub { "bar" }, # <h1>foo</h1> => <h1>bar</h1>
      'h1' => sub { undef }, # <h1>foo</h1> => disappears
      
      # sample: use $_
      'h1' => sub { uc },  # <h1>foo</h1> => <h1>FOO</h1>
      
      # sample: use arg
      'h1' => sub {
          my $node = shift;
          $node->nodeName; # <h1>foo</h1> => <h1>h1</h1>
      },
  });

=back


=head2 Filter

=over 4

=item * selector => [ $value, filter, filter, ... ]

I<Array-ref of Scalars:> Value and filters. Filter can take

A) Callback subroutine

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

You can define the your filter name using C<define_filter()>.

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


=head1 COMMON MISTAKES

The template should be XHTML/XML. Small errors might be no problem if using
XML::LibXML's C<recover> option (This moudle sets C<recover(2)> by default).
But plese take care these common mistakes.

=over 4

=item * Ampersand mark shouhd be C<&amp;>

NG.

  <a href="/?foo=&bar=">&</a>

OK.

  <a href="/?foo=&bar=">&amp</a>

Note: values doesn't need escape.

  $ts->process($template, {
      'a'      => 'foo & bar',
      'a@href' => '?foo=1&bar=2',
  })

=item * Template should have signle route element

NG. libxml uses first part only.

  <div>foo</div>
  <div>bar</div>

NG. libxml thinks this is the blank text.

  foo
  <div>bar</div>

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
