use t::TestBase;
run_template_process;

__DATA__
=== using id() function hack
--- vars
'id("foo")' => 'xxx'
--- template
<div>
    <span id="foo">replace me</span>
</div>
--- expected
<div>
    <span id="foo">xxx</span>
</div>

=== xhtml default xmlns hack
--- vars
'//span' => 'xxx'
--- template
<html xmlns="http://www.w3.org/1999/xhtml">
    <span>replace me</span>
</html>
--- expected
<html xmlns="http://www.w3.org/1999/xhtml">
    <span>xxx</span>
</html>

=== no dtd, no xml declaration
--- vars
'//foo' => 'xxx'
--- template
<root>
    <foo>bar</foo>
</root>
--- expected
<root>
    <foo>xxx</foo>
</root>

=== with dtd
--- vars
'//span' => 'xxx'
--- template
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <span>foo</span>
</html>
--- expected
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
    <span>xxx</span>
</html>

=== with xml declaration
--- vars
'//foo' => 'xxx'
--- template
<?xml version="1.0" encoding="UTF-8"?>
<root>
    <foo>bar</foo>
</root>
--- expected
<?xml version="1.0" encoding="UTF-8"?>
<root>
    <foo>xxx</foo>
</root>

=== repeat block with whitespace 1
--- vars
'//div' => sub {
    [
        { 'span' => '001' },
        { 'span' => '002' },
        { 'span' => '003' },
    ]
}
--- template
<root>
    <div>
        <img src="foo" />
        <span>bar</span>
    </div>
</root>
--- expected
<root>
    <div>
        <img src="foo" />
        <span>001</span>
    </div>
    <div>
        <img src="foo" />
        <span>002</span>
    </div>
    <div>
        <img src="foo" />
        <span>003</span>
    </div>
</root>

=== repeat block with whitespace 2
--- vars
'//div' => sub {
    [
        { 'span' => '001' },
        { 'span' => '002' },
        { 'span' => '003' },
    ]
}
--- template
<root>
    
    <div>
        <img src="foo" />
        <span>bar</span>
    </div>
</root>
--- expected
<root>
    
    <div>
        <img src="foo" />
        <span>001</span>
    </div>
    
    <div>
        <img src="foo" />
        <span>002</span>
    </div>
    
    <div>
        <img src="foo" />
        <span>003</span>
    </div>
</root>

=== repeat block with whitespace 3
--- vars
'//div' => sub {
    [
        { 'span' => '001' },
        { 'span' => '002' },
        { 'span' => '003' },
    ]
}
--- template
<root>
    test
    <div>
        <img src="foo" />
        <span>bar</span>
    </div>
</root>
--- expected
<root>
    test
    <div>
        <img src="foo" />
        <span>001</span>
    </div><div>
        <img src="foo" />
        <span>002</span>
    </div><div>
        <img src="foo" />
        <span>003</span>
    </div>
</root>

=== s/&/&amp;/ for "EntityRef: expecting ';'"
--- vars
--- template
<a href="/?foo=&foo=">foo &amp; bar & baz</a>
--- expected
<a href="/?foo=&amp;foo=">foo &amp; bar &amp; baz</a>
