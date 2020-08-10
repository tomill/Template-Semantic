use FindBin;
use lib "$FindBin::Bin/..";
use t::TestBase;
run_template_process(selector_test => 1);

__DATA__
=== xpath
--- vars
'/div' => 'xxx'
--- template
<div>foo</div>
--- expected
<div>xxx</div>

=== xpath
--- vars
'//span' => 'xxx'
--- template
<div>
<p><span>hello</span></p>
</div>
--- expected
<div>
<p><span>xxx</span></p>
</div>

=== xpath
--- vars
'/div/div/span' => 'xxx'
--- template
<div>
    <div class="foo">
        <span>boo</span>
    </div>
    <form>
        <span>boo</span>
    </form>
</div>
--- expected
<div>
    <div class="foo">
        <span>xxx</span>
    </div>
    <form>
        <span>boo</span>
    </form>
</div>

=== xpath
--- vars
'//h1' => 'xxx'
--- template
<div>
<h1>h1 -1</h1>
<h1>h1 -2</h1>
</div>
--- expected
<div>
<h1>xxx</h1>
<h1>xxx</h1>
</div>

=== xpath
--- vars
'//h1[2]' => 'xxx'
--- template
<div>
<h1>h1 -1</h1>
<h1>h1 -2</h1>
</div>
--- expected
<div>
<h1>h1 -1</h1>
<h1>xxx</h1>
</div>

=== xpath (attr)
--- vars
'//img[1]/@src' => 'xxx'
--- template
<div>
<img src="foo" />
<img src="bar" />
</div>
--- expected
<div>
<img src="xxx" />
<img src="bar" />
</div>

=== xpath
--- vars
'//*[@class="bar"]' => 'xxx'
--- template
<div>
    <span class="foo">foo</span>
    <span class="bar">bar</span>
</div>
--- expected
<div>
    <span class="foo">foo</span>
    <span class="bar">xxx</span>
</div>

=== xpath
--- vars
'//*[@id="foo"]' => 'xxx'
--- template
<div>
    <span id="foo">foo</span>
    <span id="bar">bar</span>
</div>
--- expected
<div>
    <span id="foo">xxx</span>
    <span id="bar">bar</span>
</div>

=== id()
--- vars
'id("foo")' => 'xxx'
--- template
<div>
    <span id="foo">foo</span>
    <span id="bar">bar</span>
</div>
--- expected
<div>
    <span id="foo">xxx</span>
    <span id="bar">bar</span>
</div>

=== id() (attr)
--- vars
'id("foo")/@title' => 'xxx'
--- template
<div>
    <span id="foo" title="foo">foo</span>
    <span id="bar" title="bar">bar</span>
</div>
--- expected
<div>
    <span id="foo" title="xxx">foo</span>
    <span id="bar" title="bar">bar</span>
</div>

=== css selector
--- vars
'span' => 'xxx'
--- template
<div>
<p><span>hello</span></p>
</div>
--- expected
<div>
<p><span>xxx</span></p>
</div>

=== css selector
--- vars
'div div span' => 'xxx'
--- template
<div>
    <div class="foo">
        <span>boo</span>
    </div>
    <form>
        <span>boo</span>
    </form>
</div>
--- expected
<div>
    <div class="foo">
        <span>xxx</span>
    </div>
    <form>
        <span>boo</span>
    </form>
</div>

=== css selector
--- vars
'h1' => 'xxx'
--- template
<div>
<h1>h1 -1</h1>
<h1>h1 -2</h1>
</div>
--- expected
<div>
<h1>xxx</h1>
<h1>xxx</h1>
</div>

=== css selector (attr)
--- vars
'img@src' => 'xxx'
--- template
<div>
<img src="foo" />
</div>
--- expected
<div>
<img src="xxx" />
</div>

=== css selector
--- vars
'.bar' => 'xxx'
--- template
<div>
    <span class="foo">foo</span>
    <span class="bar">bar</span>
</div>
--- expected
<div>
    <span class="foo">foo</span>
    <span class="bar">xxx</span>
</div>

=== css selector
--- vars
'span.bar' => 'xxx'
--- template
<div>
    <span class="bar">bar</span>
    <div class="bar">bar</div>
</div>
--- expected
<div>
    <span class="bar">xxx</span>
    <div class="bar">bar</div>
</div>

=== css selector (attr)
--- vars
'span.bar@title' => 'xxx'
--- template
<div>
    <span class="foo" title="foo">foo</span>
    <span class="bar" title="bar">bar</span>
</div>
--- expected
<div>
    <span class="foo" title="foo">foo</span>
    <span class="bar" title="xxx">bar</span>
</div>

=== css selector
--- vars
'#foo' => 'xxx'
--- template
<div>
    <span id="foo">foo</span>
    <span id="bar">bar</span>
</div>
--- expected
<div>
    <span id="foo">xxx</span>
    <span id="bar">bar</span>
</div>

=== css selector
--- vars
'div#foo' => 'xxx'
--- template
<div>
    <span id="foo">foo</span>
    <div id="foo">foo</div>
</div>
--- expected
<div>
    <span id="foo">foo</span>
    <div id="foo">xxx</div>
</div>

=== css selector (attr)
--- vars
'div#foo@title' => 'xxx'
--- template
<div>
    <span id="foo">foo</span>
    <div id="foo" title="foo">foo</div>
</div>
--- expected
<div>
    <span id="foo">foo</span>
    <div id="foo" title="xxx">foo</div>
</div>

=== css selector (attr)
--- vars
'div#foo/@title' => 'xxx'
--- template
<div>
    <span id="foo">foo</span>
    <div id="foo" title="foo">foo</div>
</div>
--- expected
<div>
    <span id="foo">foo</span>
    <div id="foo" title="xxx">foo</div>
</div>

=== css selector (attr)
--- vars
'@title' => 'xxx'
--- template
<div title="foo">
    <div id="foo" title="foo">foo</div>
</div>
--- expected
<div title="xxx">
    <div id="foo" title="xxx">foo</div>
</div>

=== xpath (OR)
--- vars
'//span | //h1' => 'xxx'
--- template
<div>
    <span></span>
    <h1></h1>
</div>
--- expected
<div>
    <span>xxx</span>
    <h1>xxx</h1>
</div>

=== css selector (OR)
--- vars
'span, h1' => 'xxx'
--- template
<div>
    <span></span>
    <h1></h1>
</div>
--- expected
<div>
    <span>xxx</span>
    <h1>xxx</h1>
</div>
