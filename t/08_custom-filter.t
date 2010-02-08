use strict;
use warnings;
use Test::More;

use Template::Semantic;
use Test::Requires qw(
    Text::Pipe
);

subtest 'define_filter()' => sub {
    plan tests => 1;

    my $ts = Template::Semantic->new;
    $ts->define_filter(wow => sub { "$_!!!" });

    my $output = $ts->process(\"<root></root>\n", {
        '/root' => [ 'hello', 'wow' ],
    });
    
    is($output, "<root>hello!!!</root>\n");
};

subtest 'call_filter()' => sub {
    plan tests => 1;

    my $ts = Template::Semantic->new;
    $ts->define_filter(wow => sub { "$_!!!" });

    my $output = $ts->process(\"<root>hello</root>\n", {
        '/root' => $ts->call_filter('wow'),
    });
    
    is($output, "<root>hello!!!</root>\n");
};

subtest 'define_filter() cannot overlide' => sub {
    plan tests => 1;

    my $ts = Template::Semantic->new;
    $ts->define_filter(trim => sub { "   $_   " });

    my $output = $ts->process(\"<root></root>\n", {
        '/root' => [ "  hello  ", 'trim' ],
    });
    
    is($output, "<root>hello</root>\n");
};

subtest 'filter()-able object, like Text::Pipe' => sub {
    plan tests => 1;
    
    use Text::Pipe qw/PIPE/;
    my $ts = Template::Semantic->new;
    
    my $output = $ts->process(\"<root></root>\n", {
        '/root' => [ 'hello', PIPE('UppercaseFirst') ],
    });
    
    is($output, "<root>Hello</root>\n");
};

done_testing;
