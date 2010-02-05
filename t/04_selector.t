use t::TestBase;
run_template_process(selector_test => 1);

__DATA__
=== xpath
--- vars
'/html' => 'xxx'
--- template
<html>foo</html>
--- expected
<html>xxx</html>

=== xpath
--- vars
'//title' => 'xxx'
--- template
<html>
<head><title>hello</title></head>
</html>
--- expected
<html>
<head><title>xxx</title></head>
</html>

=== xpath
--- vars
'/html/body/div/span' => 'xxx'
--- template
<html>
    <body>
        <div class="foo">
            <span>boo</span>
        </div>
        <form>
            <span>boo</span>
        </form>
    </body>
</html>
--- expected
<html>
    <body>
        <div class="foo">
            <span>xxx</span>
        </div>
        <form>
            <span>boo</span>
        </form>
    </body>
</html>

=== xpath
--- vars
'//h1' => 'xxx'
--- template
<html>
<h1>h1 -1</h1>
<h1>h1 -2</h1>
</html>
--- expected
<html>
<h1>xxx</h1>
<h1>xxx</h1>
</html>

=== xpath
--- vars
'//h1[2]' => 'xxx'
--- template
<html>
<h1>h1 -1</h1>
<h1>h1 -2</h1>
</html>
--- expected
<html>
<h1>h1 -1</h1>
<h1>xxx</h1>
</html>

=== xpath (attr)
--- vars
'//meta[1]/@content' => 'xxx'
--- template
<html>
<meta name="foo" content="foo"/>
</html>
--- expected
<html>
<meta name="foo" content="xxx"/>
</html>

=== xpath
--- vars
'//*[@class="bar"]' => 'xxx'
--- template
<html>
    <span class="foo">foo</span>
    <span class="bar">bar</span>
</html>
--- expected
<html>
    <span class="foo">foo</span>
    <span class="bar">xxx</span>
</html>

=== xpath
--- vars
'//*[@id="foo"]' => 'xxx'
--- template
<html>
    <span id="foo">foo</span>
    <span id="bar">bar</span>
</html>
--- expected
<html>
    <span id="foo">xxx</span>
    <span id="bar">bar</span>
</html>

=== xpath
--- vars
'id("foo")' => 'xxx'
--- template
<html>
    <span id="foo">foo</span>
    <span id="bar">bar</span>
</html>
--- expected
<html>
    <span id="foo">xxx</span>
    <span id="bar">bar</span>
</html>

=== xpath (attr)
--- vars
'id("foo")/@title' => 'xxx'
--- template
<html>
    <span id="foo" title="foo">foo</span>
    <span id="bar" title="bar">bar</span>
</html>
--- expected
<html>
    <span id="foo" title="xxx">foo</span>
    <span id="bar" title="bar">bar</span>
</html>

=== css selector
--- vars
'title' => 'xxx'
--- template
<html>
<head><title>hello</title></head>
</html>
--- expected
<html>
<head><title>xxx</title></head>
</html>

=== css selector
--- vars
'html body div span' => 'xxx'
--- template
<html>
    <body>
        <div class="foo">
            <span>boo</span>
        </div>
        <form>
            <span>boo</span>
        </form>
    </body>
</html>
--- expected
<html>
    <body>
        <div class="foo">
            <span>xxx</span>
        </div>
        <form>
            <span>boo</span>
        </form>
    </body>
</html>

=== css selector
--- vars
'body span' => 'xxx'
--- template
<html>
    <body>
        <div class="foo">
            <span>boo</span>
        </div>
        <form>
            <span>boo</span>
        </form>
    </body>
</html>
--- expected
<html>
    <body>
        <div class="foo">
            <span>xxx</span>
        </div>
        <form>
            <span>xxx</span>
        </form>
    </body>
</html>

=== css selector
--- vars
'h1' => 'xxx'
--- template
<html>
<h1>h1 -1</h1>
<h1>h1 -2</h1>
</html>
--- expected
<html>
<h1>xxx</h1>
<h1>xxx</h1>
</html>

=== css selector (attr)
--- vars
'meta@content' => 'xxx'
--- template
<html>
<meta name="foo" content="foo"/>
</html>
--- expected
<html>
<meta name="foo" content="xxx"/>
</html>

=== css selector
--- vars
'.bar' => 'xxx'
--- template
<html>
    <span class="foo">foo</span>
    <span class="bar">bar</span>
</html>
--- expected
<html>
    <span class="foo">foo</span>
    <span class="bar">xxx</span>
</html>

=== css selector
--- vars
'span.bar' => 'xxx'
--- template
<html>
    <span class="bar">bar</span>
    <div class="bar">bar</div>
</html>
--- expected
<html>
    <span class="bar">xxx</span>
    <div class="bar">bar</div>
</html>

=== css selector (attr)
--- vars
'span.bar@title' => 'xxx'
--- template
<html>
    <span class="foo" title="foo">foo</span>
    <span class="bar" title="bar">bar</span>
</html>
--- expected
<html>
    <span class="foo" title="foo">foo</span>
    <span class="bar" title="xxx">bar</span>
</html>

=== css selector
--- vars
'#foo' => 'xxx'
--- template
<html>
    <span id="foo">foo</span>
    <span id="bar">bar</span>
</html>
--- expected
<html>
    <span id="foo">xxx</span>
    <span id="bar">bar</span>
</html>

=== css selector
--- vars
'div#foo' => 'xxx'
--- template
<html>
    <span id="foo">foo</span>
    <div id="foo">foo</div>
</html>
--- expected
<html>
    <span id="foo">foo</span>
    <div id="foo">xxx</div>
</html>

=== css selector (attr)
--- vars
'div#foo@title' => 'xxx'
--- template
<html>
    <span id="foo">foo</span>
    <div id="foo" title="foo">foo</div>
</html>
--- expected
<html>
    <span id="foo">foo</span>
    <div id="foo" title="xxx">foo</div>
</html>

=== css selector (attr)
--- vars
'div#foo/@title' => 'xxx'
--- template
<html>
    <span id="foo">foo</span>
    <div id="foo" title="foo">foo</div>
</html>
--- expected
<html>
    <span id="foo">foo</span>
    <div id="foo" title="xxx">foo</div>
</html>

=== css selector (attr)
--- vars
'@title' => 'xxx'
--- template
<html title="foo">
    <div id="foo" title="foo">foo</div>
</html>
--- expected
<html title="xxx">
    <div id="foo" title="xxx">foo</div>
</html>
