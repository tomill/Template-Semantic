use inc::Module::Install;
name 'Template-Semantic';
all_from    'lib/Template/Semantic.pm';
readme_from 'lib/Template/Semantic.pm';
# homepage 'http://e8y.net/';

requires_any_moose;
requires '';

author_tests 'xt';
test_requires 'Test::More' => 0.88;
# use_test_base

# install_share;

auto_include_deps;
auto_set_repository;
githubmeta;

bundle_local_lib;

WriteAll;
