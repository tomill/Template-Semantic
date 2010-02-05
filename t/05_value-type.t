use strict;
use warnings;
use Test::Base; plan tests => 1 * blocks;

use Template::Semantic;

filters {
    vars => [qw/ eval hash /],
};

my $ts = Template::Semantic->new;

run {
    my $block = shift;
    my $doc = $ts->process(\$block->template, $block->vars);
    is($doc->as_string, $block->expected, $block->name);
};

__DATA__
=== elem x scalar
--- vars
'//span' => '<xxx>'
--- template
<root>
    <div>
        <span>bar</span>
    </div>
</root>
--- expected
<root>
    <div>
        <span>&lt;xxx&gt;</span>
    </div>
</root>

=== attr x scalar
--- vars
'//span/@title' => '<xxx>'
--- template
<root>
    <div>
        <span title="bar">bar</span>
    </div>
</root>
--- expected
<root>
    <div>
        <span title="&lt;xxx&gt;">bar</span>
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

=== attr x undef
--- vars
'//span/@title' => undef
--- template
<root>
    <div>
        <span title="bar">bar</span>
    </div>
</root>
--- expected
<root>
    <div>
        <span>bar</span>
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

=== attr x scalarref
--- vars
'//span/@title' => \'xxx'
--- template
<root>
    <div>
        <span title="bar">bar</span>
    </div>
</root>
--- expected
<root>
    <div>
        <span title="xxx">bar</span>
    </div>
</root>

=== elem x XML::LibXML::Node (text node)
--- vars
use XML::LibXML;
'//div' => XML::LibXML::Text->new('<xxx>')
--- template
<root>
    <div>bar</div>
    <div>bar</div>
</root>
--- expected
<root>
    <div>&lt;xxx&gt;</div>
    <div>&lt;xxx&gt;</div>
</root>

=== attr x XML::LibXML::Node (text node)
--- vars
use XML::LibXML;
'//div/@title' => XML::LibXML::Text->new('<xxx>')
--- template
<root>
    <div title="foo">foo</div>
    <div>bar</div>
</root>
--- expected
<root>
    <div title="&lt;xxx&gt;">foo</div>
    <div>bar</div>
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

=== attr x sub (return undef)
--- vars
'//span/@title' => sub { undef }
--- template
<root>
    <span title="bar">bar</span>
</root>
--- expected
<root>
    <span>bar</span>
</root>

=== elem x sub (return hashref)
--- vars
'//div' => sub {
    { 'span' => 'xxx' };
}
--- template
<root>
    <div>
        <img src="foo"/>
        <span>bar</span>
    </div>
</root>
--- expected
<root>
    <div>
        <img src="foo"/>
        <span>xxx</span>
    </div>
</root>

=== elem x sub (return arrayref)
--- vars
'//div' => sub {
    [
        { 'span' => '001' },
        { 'span' => '002' },
    ]
}
--- template
<root>
    <div>
        <img src="foo"/>
        <span>bar</span>
    </div>
</root>
--- expected
<root>
    <div>
        <img src="foo"/>
        <span>001</span>
    </div>
    <div>
        <img src="foo"/>
        <span>002</span>
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

=== elem x unknown type
--- vars
package Boo;
use overload q{""} => sub { 'Booo!' }, fallback => 1;

package main;
'//span' => do { bless {}, 'Boo' };
--- template
<root>
    <div>
        <span>bar</span>
    </div>
</root>
--- expected
<root>
    <div>
        <span>Booo!</span>
    </div>
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

=== attr x arrayref (filters)
--- vars
no warnings 'ambiguous'; # for Test::Base::Filter 'join'
'id("foo")/@class' => [ sub { "x-test-b $_ x-test-a" }, sub { join " ", sort split } ]
--- template
<root>
    <div id="foo" class="foo bar">foo</div>
</root>
--- expected
<root>
    <div id="foo" class="bar foo x-test-a x-test-b">foo</div>
</root>
