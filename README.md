# NAME

Template::Semantic - Use pure XHTML/XML as a template

# SYNOPSIS

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

# DESCRIPTION

Template::Semantic is a template engine for XHTML/XML based on [XML::LibXML](https://metacpan.org/pod/XML%3A%3ALibXML)
that doesn't use any template syntax. This module takes pure XHTML/XML as a template,
and uses XPath or CSS selectors to assign values.

# METHODS

- $ts = Template::Semantic->new( %options )

    Constructs a new `Template::Semantic` object.

        my $ts = Template::Semantic->new(
            ...
        );
        my $res = $ts->process(...);

    If you do not want to change the options from the defaults, you may skip
    `new()` and call `process()` directly:

        my $res = Template::Semantic->process(...);

    Set %options if you want to change parser options:

    - parser => $your\_libxml\_parser

        Set if you want to replace XML parser. It should be [XML::LibXML](https://metacpan.org/pod/XML%3A%3ALibXML) based.

            my $ts = Template::Semantic->new(
                parser => My::LibXML->new,
            );

    - (others)

        All other parameters are applied to the XML parser as method calls
        (`$parser->$key($value)`). Template::Semantic uses this configuration
        by default:

            no_newwork => 1  # faster
            recover    => 2  # "no warnings" style

        See ["PARSER OPTIONS" in XML::LibXML::Parser](https://metacpan.org/pod/XML%3A%3ALibXML%3A%3AParser#PARSER-OPTIONS) for details.

            # "use strict;" style
            my $ts = Template::Semantic->new( recover => 0 );

            # "use warnings;" style
            my $ts = Template::Semantic->new( recover => 1 );

- $res = $ts->process($filename, \\%vars)
- $res = $ts->process(\\$text, \\%vars)
- $res = $ts->process(FH, \\%vars)

    Process a template and return a [Template::Semantic::Document](https://metacpan.org/pod/Template%3A%3ASemantic%3A%3ADocument) object.

    The first parameter is the input template, which may take one of several forms:

        # filename
        my $res = Template::Semantic->process('template.html', $vars);

        # text reference
        my $res = Template::Semantic->process(\'<html><body>foo</body></html>', $vars);

        # file handle, GLOB
        my $res = Template::Semantic->process($fh, $vars);
        my $res = Template::Semantic->process(\*DATA, $vars);

    The second parameter is a value set to bind the template. $vars should be a
    hash-ref of selectors and corresponding values.  See the ["SELECTOR"](#selector) and
    ["VALUE TYPE"](#value-type) sections below.  For example:

        {
          '.foo'    => 'hello',
          '//title' => 'This is a title',
        }

- $ts->define\_filter($filter\_name, \\&code)
- $ts->call\_filter($filter\_name)

    See the ["Filter"](#filter) section.

# SELECTOR

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

1\. You can use xpath `'//div'` without using [XML::LibXML::XPathContext](https://metacpan.org/pod/XML%3A%3ALibXML%3A%3AXPathContext)
even if your template has default namespace (`<html xmlns="...">`).

2\. You can use `'id("foo")'` function to find element with `id="foo"`
instead of `xml:id="foo"` without DTD. Note: use `'//*[@xml:id="foo"]'`
if your template uses `xml:id="foo"`.

3\. You can `'@attr'` syntax with CSS selector that specifies the attribute.
This is original syntax of this module.

# VALUE TYPE

## Basics

- selector => $text

    _Scalar:_ Replace the inner content with this as Text.

        $ts->process($template, {
            'h1' => 'foo & bar',   # <h1></h1> =>
                                   # <h1>foo &amp; bar</h1>

            '.foo@href' => '/foo', # <a href="#" class="foo">bar</a> =>
                                   # <a href="/foo" class="foo">bar</a>
        });

- selector => \\$html

    _Scalar-ref:_ Replace the inner content with this as fragment XML/HTML.

        $ts->process($template, {
            'h1' => \'<a href="#">foo</a>bar', # <h1></h1> =>
                                               # <h1><a href="#">foo</a>bar</h1>
        });

- selector => undef

    _undef:_ Delete the element/attirbute that the selector indicates.

        $ts->process($template, {
            'h1'            => undef, # <div><h1>foo</h1>bar</div> =>
                                      # <div>bar</div>

            'div.foo@class' => undef, # <div class="foo">foo</div> =>
                                      # <div>foo</div>
        });

- selector => XML::LibXML::Node

    Replace the inner content by the node. XML::LibXML::Attr isn't supported.

        $ts->process($template, {
            'h1' => do { XML::LibXML::Text->new('foo') },
        });

- selector => Template::Semantic::Document

    Replace the inner content by another `process()`-ed result.

        $ts->process('wrapper.html', {
            'div#content' => $ts->process('inner.html', ...),
        });

- selector => { 'selector' => $value, ... }

    _Hash-ref:_ Sub query of the part.

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

## Loop

- selector => \[ \\%row, \\%row, ... \]

    _Array-ref of Hash-refs:_ Loop the part as template. Each item
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

## Callback

- selector => \\&foo

    _Code-ref:_ Callback subroutine. The callback receives

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

## Filter

- selector => \[ $value, filter, filter, ... \]

    _Array-ref of Scalars:_ Value and filters. Filters may be

    A) Callback subroutine (code reference)

    B) Defined filter name

    C) Object like [Text::Pipe](https://metacpan.org/pod/Text%3A%3APipe) (`it->can('filter')`)

        $ts->process($template, {
            'h1' => [ 'foo', sub { uc }, sub { "$_!" } ], # => <h1>FOO!</h1>
            'h2' => [ ' foo ', 'trim', sub { "$_!" } ],   # => <h2>FOO!</h2>
            'h3' => [ 'foo', PIPE('UppercaseFirst') ],    # => <h3>Foo</h3>
        });

    - Defined basic filters

        Some basic filters included. See [Template::Semantic::Filter](https://metacpan.org/pod/Template%3A%3ASemantic%3A%3AFilter).

    - $ts->define\_filter($filter\_name, \\&code)

        You can define your own filters using `define_filter()`.

            use Text::Markdown qw/markdown/;
            $ts->define_filter(markdown => sub { \ markdown($_) })
            $ts->process($template, {
                'div.content' => [ $text, 'markdown' ],
            });

    - $code = $ts->call\_filter($filter\_name)

        Accessor to defined filter.

            $ts->process($template, {
                'div.entry'      => ...,
                'div.entry-more' => ...,
            })->process({
                'div.entry, div.entry-more' => $ts->call_filter('markdown'),
            });

# SEE ALSO

[Template::Semantic::Cookbook](https://metacpan.org/pod/Template%3A%3ASemantic%3A%3ACookbook)

[Template::Semantic::Document](https://metacpan.org/pod/Template%3A%3ASemantic%3A%3ADocument)

[XML::LibXML](https://metacpan.org/pod/XML%3A%3ALibXML), [HTML::Selector::XPath](https://metacpan.org/pod/HTML%3A%3ASelector%3A%3AXPath)

I got a lot of ideas from [Template](https://metacpan.org/pod/Template), [Template::Refine](https://metacpan.org/pod/Template%3A%3ARefine),
[Web::Scraper](https://metacpan.org/pod/Web%3A%3AScraper). thanks!

# AUTHOR

Naoki Tomita <tomita@cpan.org>

Feedback, patches, POD English check are always welcome!

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
