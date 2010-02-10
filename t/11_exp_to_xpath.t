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
//*[contains(concat(' ', @class, ' '), ' foo ')]
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
