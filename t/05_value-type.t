use t::TestBase;
run_template_process;

__DATA__
=== elem x scalar
--- vars
'//span' => 'xxx > yyy'
--- template
<root>
    <div>
        <span>bar</span>
    </div>
</root>
--- expected
<root>
    <div>
        <span>xxx &gt; yyy</span>
    </div>
</root>

=== elem x undef
--- vars
'//span' => undef
--- template
<root>
    <div>
        <span title="bar">bar</span>
    </div>
</root>
--- expected
<root>
    <div>
        
    </div>
</root>

=== elem x scalarref
--- vars
'//span' => \'hey <b>you</b>!'
--- template
<root>
    <div>
        <span>bar</span>
    </div>
</root>
--- expected
<root>
    <div>
        <span>hey <b>you</b>!</span>
    </div>
</root>

=== elem x XML::LibXML::Node (text node)
--- vars
use XML::LibXML;
'//div' => XML::LibXML::Text->new('xxx > yyy')
--- template
<root>
    <div>bar</div>
    <div>bar</div>
</root>
--- expected
<root>
    <div>xxx &gt; yyy</div>
    <div>xxx &gt; yyy</div>
</root>

=== elem x XML::LibXML::Node (deep node)
--- vars
use XML::LibXML;
'//div' => XML::LibXML->new->parse_string('<span><b>a</b><i>aaa</i></span>')->documentElement
--- template
<root>
    <div>bar</div>
    <div>bar</div>
</root>
--- expected
<root>
    <div><span><b>a</b><i>aaa</i></span></div>
    <div><span><b>a</b><i>aaa</i></span></div>
</root>

=== elem x sub (using $_)
--- vars
'//span' => sub { uc }
--- template
<root>
    <span>bar</span>
</root>
--- expected
<root>
    <span>BAR</span>
</root>

=== elem x sub (using @_)
--- vars
'//span' => sub {
    my $node = shift;
    return ref($node) .'/'. $node->nodeName .'/'. $node->textContent;
}
--- template
<root>
    <span>bar</span>
</root>
--- expected
<root>
    <span>XML::LibXML::Element/span/bar</span>
</root>

=== elem x sub (add attr)
--- vars
'//div' => sub {
    shift->setAttribute('class', 'foo');
    \$_;
}
--- template
<root>
    <div><span>bar</span></div>
</root>
--- expected
<root>
    <div class="foo"><span>bar</span></div>
</root>

=== elem x sub (return undef)
--- vars
'//span' => sub { undef }
--- template
<root>
    <span>bar</span>
</root>
--- expected
<root>
    
</root>

=== elem x sub (do nothing)
--- vars
'//span' => sub { \$_ }
--- template
<root>
    <span>foo<b class="bar">bar</b></span>
</root>
--- expected
<root>
    <span>foo<b class="bar">bar</b></span>
</root>

=== elem x Template::Semantic object 1
--- vars
'//div' => Template::Semantic->process(\'<span></span>', {
    'span' => 'xxx',
})
--- template
<root>
    <div></div>
</root>
--- expected
<root>
    <div><span>xxx</span></div>
</root>

=== elem x Template::Semantic object 2
--- vars
'//div' => Template::Semantic->process(\'<span></span>', {
    'span' => 'xxx',
})
--- template
<root>
    <div></div>
    <div></div>
</root>
--- expected
<root>
    <div><span>xxx</span></div>
    <div><span>xxx</span></div>
</root>

=== elem x Template::Semantic object 3
--- vars
'//div' => Template::Semantic->process(\'<?xml version="1.0"?><span></span>', {
    'span' => 'xxx',
})
--- template
<root>
    <div></div>
</root>
--- expected
<root>
    <div><span>xxx</span></div>
</root>

=== elem x unknown type
--- vars
package Boo;
use overload q{""} => sub { 'Booo!' }, fallback => 1;

package main;
'//span' => do { bless {}, 'Boo' };
--- template
<root>
    <span>bar</span>
</root>
--- expected
<root>
    <span>Booo!</span>
</root>

=== elem x hashref (xpath)
--- vars
'id("bar")' => {
    '/span' => 'xxx',
}
--- template
<root>
    <div id="foo"><span>foo</span></div>
    <div id="bar"><span>bar</span></div>
</root>
--- expected
<root>
    <div id="foo"><span>foo</span></div>
    <div id="bar"><span>xxx</span></div>
</root>

=== elem x hashref (css selector)
--- vars
'id("bar")' => {
    'span' => 'xxx',
}
--- template
<root>
    <div id="foo"><span>foo</span></div>
    <div id="bar"><span>bar</span></div>
</root>
--- expected
<root>
    <div id="foo"><span>foo</span></div>
    <div id="bar"><span>xxx</span></div>
</root>

=== elem x arrayref of hashref list (simple)
--- vars
'ul.list li' => [
    { '/li' => 'AAA'  },
    { '/li' => 'BBB' },
]
--- template
<root>
    <ul class="list">
        <li>xxx</li>
    </ul>
</root>
--- expected
<root>
    <ul class="list">
        <li>AAA</li>
        <li>BBB</li>
    </ul>
</root>

=== elem x arrayref of hashref list
--- vars
'table.list tr' => [
    { 'th' => 'A', 'td' => '001' },
    { 'th' => 'B', 'td' => '002' },
]
--- template
<root>
    <table class="list">
        <tr>
            <th>foo</th>
            <td>bar</td>
        </tr>
    </table>
</root>
--- expected
<root>
    <table class="list">
        <tr>
            <th>A</th>
            <td>001</td>
        </tr>
        <tr>
            <th>B</th>
            <td>002</td>
        </tr>
    </table>
</root>

=== elem x arrayref (filters)
--- vars
package main;
'id("foo")' => [ ' 100000 ', 'trim', sub { '-' . $_ }, 'comma' ]
--- template
<root>
    <div id="foo">foo</div>
</root>
--- expected
<root>
    <div id="foo">-100,000</div>
</root>

=== elem x sub (return hashref)
--- vars
'//div' => sub {
    { 'span' => 'xxx', 'img@src' => 'xxx.jpg' };
}
--- template
<root>
    <div>
        <span>bar</span>
        <img src="foo"/>
    </div>
</root>
--- expected
<root>
    <div>
        <span>xxx</span>
        <img src="xxx.jpg"/>
    </div>
</root>

=== elem x sub (return arrayref)
--- vars
'//div' => sub {
    [
        { 'span' => '001', 'img@src' => '001.jpg' },
        { 'span' => '002', 'img@src' => '002.jpg' },
    ]
}
--- template
<root>
    <div>
        <span>bar</span>
        <img src="foo"/>
    </div>
</root>
--- expected
<root>
    <div>
        <span>001</span>
        <img src="001.jpg"/>
    </div>
    <div>
        <span>002</span>
        <img src="002.jpg"/>
    </div>
</root>

=== elem x sub (using default filter)
--- vars
'//span' => \&Template::Semantic::Filter::trim
--- template
<root>
    <span>  foo   </span>
    <span> bar </span>
</root>
--- expected
<root>
    <span>foo</span>
    <span>bar</span>
</root>



=== attr x scalar
--- vars
'//span/@title' => 'xxx > yyy'
--- template
<root>
    <span title="bar">bar</span>
</root>
--- expected
<root>
    <span title="xxx &gt; yyy">bar</span>
</root>

=== attr x undef
--- vars
'//span/@title' => undef
--- template
<root>
    <span title="bar">bar</span>
</root>
--- expected
<root>
    <span>bar</span>
</root>

=== attr x scalar-ref
--- vars
'//span/@title' => \'<b>xxx</b> > yyy'
--- template
<root>
    <span title="bar">bar</span>
</root>
--- expected
<root>
    <span title="xxx &gt; yyy">bar</span>
</root>

=== attr x XML::LibXML::Node
--- vars
use XML::LibXML;
'//span/@title' => XML::LibXML::Text->new('xxx > yyy')
--- template
<root>
    <span title="foo">foo</span>
</root>
--- expected
<root>
    <span title="xxx &gt; yyy">foo</span>
</root>

=== attr x arrayref (filters)
--- vars
no warnings 'ambiguous'; # for Test::Base::Filter 'join'
'id("foo")/@class' => [ sub { "x-test-b $_ x-test-a" }, sub { join " ", sort split } ]
--- template
<root>
    <span id="foo" class="foo bar">foo</span>
</root>
--- expected
<root>
    <span id="foo" class="bar foo x-test-a x-test-b">foo</span>
</root>

=== attr x sub (using $_)
--- vars
'//span/@title' => sub { uc }
--- template
<root>
    <span title="bar">bar</span>
</root>
--- expected
<root>
    <span title="BAR">bar</span>
</root>

=== attr x sub (using @_)
--- vars
'//span/@title' => sub {
    my $node = shift;
    return ref($node) .'/'. $node->nodeName .'/'. $node->textContent;
}
--- template
<root>
    <span title="bar">bar</span>
</root>
--- expected
<root>
    <span title="XML::LibXML::Attr/title/bar">bar</span>
</root>

=== attr x sub (do nothing)
--- vars
'span@class' => sub { \$_ }
--- template
<root>
    <span class="xxx yyy zzz">foo</span>
</root>
--- expected
<root>
    <span class="xxx yyy zzz">foo</span>
</root>



=== text x scalar
--- vars
'//span/text()' => 'xxx > yyy'
--- template
<div>
    <span>bar</span>
</div>
--- expected
<div>
    <span>xxx &gt; yyy</span>
</div>

=== text x undef
--- vars
'//span/text()' => undef
--- template
<root>
    <span>bar</span>
</root>
--- expected
<root>
    <span/>
</root>

=== text x scalar-ref
--- vars
'//span/text()' => \'<b>xxx</b> > yyy'
--- template
<root>
    <span>bar</span>
</root>
--- expected
<root>
    <span>xxx &gt; yyy</span>
</root>

=== text x XML::LibXML::Node
--- vars
use XML::LibXML;
'//span/text()' => XML::LibXML::Text->new('xxx > yyy')
--- template
<root>
    <span>bar</span>
</root>
--- expected
<root>
    <span>xxx &gt; yyy</span>
</root>

=== text x sub (using $_)
--- vars
'//span/text()' => sub { uc }
--- template
<root>
    <span>bar</span>
</root>
--- expected
<root>
    <span>BAR</span>
</root>

=== text x sub (using @_)
--- vars
'//span/text()' => sub {
    my $node = shift;
    return ref($node) .'/'. $node->nodeName .'/'. $node->textContent;
}
--- template
<root>
    <span>bar</span>
</root>
--- expected
<root>
    <span>XML::LibXML::Text/#text/bar</span>
</root>

=== text x sub (do nothing)
--- vars
'//span/text()' => sub { \$_ }
--- template
<root>
    <span>foo &amp; bar</span>
</root>
--- expected
<root>
    <span>foo &amp; bar</span>
</root>



=== comment x scalar
--- vars
'//comment()[1]' => 'xxx > yyy'
--- template
<div>
    <!-- foo -->
</div>
--- expected
<div>
    <!--xxx > yyy-->
</div>

=== comment x undef
--- vars
'//comment()[1]' => undef
--- template
<root>
    <!-- foo -->
</root>
--- expected
<root>
    
</root>

=== comment x scalar-ref
--- vars
'//comment()[1]' => \'<b>xxx</b> > yyy'
--- template
<root>
    <!-- foo -->
</root>
--- expected
<root>
    <!--<b>xxx</b> > yyy-->
</root>

=== comment x XML::LibXML::Node
--- vars
use XML::LibXML;
'//comment()[1]' => XML::LibXML::Text->new('xxx > yyy')
--- template
<root>
    <!-- foo -->
</root>
--- expected
<root>
    <!--xxx > yyy-->
</root>

=== comment x sub (using $_)
--- vars
'//comment()[1]' => sub { uc }
--- template
<root>
    <!-- foo > bar -->
</root>
--- expected
<root>
    <!-- FOO > BAR -->
</root>

=== comment x sub (using @_)
--- vars
'//comment()[1]' => sub {
    my $node = shift;
    return ref($node) .'/'. $node->nodeName .'/'. $node->textContent;
}
--- template
<root>
    <!-- foo -->
</root>
--- expected
<root>
    <!--XML::LibXML::Comment/#comment/ foo -->
</root>

=== comment x sub (do nothing)
--- vars
'//comment()[1]' => sub { \$_ }
--- template
<root>
    <!-- foo > bar -->
</root>
--- expected
<root>
    <!-- foo > bar -->
</root>



=== cdata x scalar
--- vars
'//text()[2]' => 'xxx > yyy'
--- template
<div>
    <![CDATA[ foo > bar ]]>
</div>
--- expected
<div>
    <![CDATA[xxx > yyy]]>
</div>

=== cdata x undef
--- vars
'//text()[2]' => undef
--- template
<root>
    <![CDATA[ foo ]]>
</root>
--- expected
<root>
    
</root>

=== cdata x scalar-ref
--- vars
'//text()[2]' => \'<b>xxx</b> > yyy'
--- template
<root>
    <![CDATA[ foo ]]>
</root>
--- expected
<root>
    <![CDATA[<b>xxx</b> > yyy]]>
</root>

=== cdata x XML::LibXML::Node
--- vars
use XML::LibXML;
'//text()[2]' => XML::LibXML::Text->new('xxx > yyy')
--- template
<root>
    <![CDATA[ foo ]]>
</root>
--- expected
<root>
    <![CDATA[xxx > yyy]]>
</root>

=== cdata x sub (using $_)
--- vars
'//text()[2]' => sub { uc }
--- template
<root>
    <![CDATA[ foo > bar ]]>
</root>
--- expected
<root>
    <![CDATA[ FOO > BAR ]]>
</root>

=== cdata x sub (using @_)
--- vars
'//text()[2]' => sub {
    my $node = shift;
    return ref($node) .'/'. $node->nodeName .'/'. $node->textContent;
}
--- template
<root>
    <![CDATA[ foo ]]>
</root>
--- expected
<root>
    <![CDATA[XML::LibXML::CDATASection/#cdata-section/ foo ]]>
</root>

=== cdata x sub (do nothing)
--- vars
'//text()[2]' => sub { \$_ }
--- template
<root>
    <![CDATA[ foo > bar ]]>
</root>
--- expected
<root>
    <![CDATA[ foo > bar ]]>
</root>
