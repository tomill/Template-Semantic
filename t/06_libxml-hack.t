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
=== using id() function hack
--- vars
'id("foo")' => 'xxx'
--- template
<html>
    <span id="foo">replace me</span>
</html>
--- expected
<html>
    <span id="foo">xxx</span>
</html>

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

