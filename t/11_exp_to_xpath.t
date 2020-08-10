use strict;
use warnings;
use Test::Base; plan tests => 1 * blocks;

use Template::Semantic;

filters {
    exp => 'chomp',
    xpath => 'chomp',
};

run {
    my $block = shift;
    my $xpath = Template::Semantic::Document->_exp_to_xpath($block->exp);
    is($xpath, $block->xpath, $block->exp);
};

__DATA__

===
--- exp
/
--- xpath
/

===
--- exp
/foo
--- xpath
/foo

===
--- exp
//
--- xpath
//

===
--- exp
./
--- xpath
./

===
--- exp
.
--- xpath
.

===
--- exp
.foo
--- xpath
//*[contains(concat(' ', normalize-space(@class), ' '), ' foo ')]

===
--- exp
id("foo")
--- xpath
//*[@id="foo"]

===
--- exp
foo@attr
--- xpath
//foo/@attr

===
--- exp
foo/@attr
--- xpath
//foo/@attr

===
--- exp
@attr
--- xpath
//@attr

===
--- exp
*@foo
--- xpath
//*/@foo

===
--- exp
E F@foo
--- xpath
//E//F/@foo

===
--- exp
E > F@foo
--- xpath
//E/F/@foo

===
--- exp
E:first-child@foo
--- xpath
//E[count(preceding-sibling::*) = 0 and parent::*]/@foo

===
--- exp
F E:first-child@foo
--- xpath
//F//E[count(preceding-sibling::*) = 0 and parent::*]/@foo

===
--- exp
F > E:first-child@foo
--- xpath
//F/E[count(preceding-sibling::*) = 0 and parent::*]/@foo

===
--- exp
E:lang(c)@foo
--- xpath
//E[@xml:lang='c' or starts-with(@xml:lang, 'c-')]/@foo

===
--- exp
E + F@foo
--- xpath
//E/following-sibling::*[1]/self::F/@foo

===
--- exp
E + #bar@foo
--- xpath
//E/following-sibling::*[1]/self::*[@id='bar']/@foo

===
--- exp
E + .bar@foo
--- xpath
//E/following-sibling::*[1]/self::*[contains(concat(' ', normalize-space(@class), ' '), ' bar ')]/@foo

===
--- exp
E[foo]@foo
--- xpath
//E[@foo]/@foo

===
--- exp
E[foo="warning"]@foo
--- xpath
//E[@foo='warning']/@foo

===
--- exp
E[foo~="warning"]@foo
--- xpath
//E[contains(concat(' ', @foo, ' '), ' warning ')]/@foo

===
--- exp
E[lang|="en"]@foo
--- xpath
//E[@lang='en' or starts-with(@lang, 'en-')]/@foo

===
--- exp
DIV.warning@foo
--- xpath
//DIV[contains(concat(' ', normalize-space(@class), ' '), ' warning ')]/@foo

===
--- exp
E#myid@foo
--- xpath
//E[@id='myid']/@foo

===
--- exp
E:nth-child(1)@foo
--- xpath
//E[count(preceding-sibling::*) = 0 and parent::*]/@foo

===
--- exp
@foo, bar
--- xpath
//@foo | //bar

--- exp
foo, @bar
--- xpath
//foo | //@bar

===
--- exp
 foo, @bar
--- xpath
//foo | //@bar

===
--- exp
@foo, @bar
--- xpath
//@foo | //@bar

===
--- exp
 @foo, bar
--- xpath
//@foo | //bar

===
--- exp
#foo@foo, bar@bar, @baz
--- xpath
//*[@id='foo']/@foo | //bar/@bar | //@baz

===
--- exp
a[foo="@xxx,yyy"]@foo, bar@bar
--- xpath
//a[@foo='@xxx,yyy']/@foo | //bar/@bar

===
--- exp
a[foo="xxx,yyy"], b[bar="@aaa"]@bar, c@baz
--- xpath
//a[@foo='xxx,yyy'] | //b[@bar='@aaa']/@bar | //c/@baz

