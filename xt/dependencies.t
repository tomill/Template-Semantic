use Test::More;
eval {
  use Test::Dependencies
      exclude => [qw( Test::Dependencies Template::Semantic )],
      style => 'light';
};
plan skip_all => "Test::Dependencies is not installed." if $@;
ok_dependencies();
