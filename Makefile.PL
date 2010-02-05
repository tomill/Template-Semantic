use inc::Module::Install;
name 'Template-Semantic';
all_from    'lib/Template/Semantic.pm';
readme_from 'lib/Template/Semantic.pm';

requires 'XML::LibXML' => 1.69;
requires 'HTML::Selector::XPath';
requires 'Scalar::Util' => 1.19;

test_requires 'Test::More' => 0.88;
test_requires 'Test::Requires';
use_test_base
author_tests 'xt';

auto_include_deps;
auto_set_repository;

WriteAll;
