use inc::Module::Install;
all_from 'lib/Template/Semantic.pm';

readme_from;
repository 'http://github.com/tomi-ru/Template-Semantic';
bugtracker 'http://github.com/tomi-ru/Template-Semantic/issues';

requires 'XML::LibXML' => 1.69;
requires 'HTML::Selector::XPath' => 0.09;
requires 'Scalar::Util' => 1.19;

test_requires 'Test::More' => 0.94; # subtest
test_requires 'Test::Base';
test_requires 'Test::Requires';
use_test_base;
auto_include_deps;

tests_recursive;

WriteAll;
