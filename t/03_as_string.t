use strict;
use warnings;
use Test::More;

use Template::Semantic;

my $input = <<END
<root>
    <span>replace me</span>
</root>
END
;

my $expected = <<END
<root>
    <span>HELLO WORLD</span>
</root>
END
;

subtest 'overload q{""}' => sub {
    plan tests => 1;

    my $output = Template::Semantic->process(\$input, {
        'span' => 'HELLO WORLD',
    });
    
    is("$output", $expected);
};

subtest '->as_string()' => sub {
    plan tests => 1;

    my $output = Template::Semantic->process(\$input, {
        'span' => 'HELLO WORLD',
    });
    
    is($output->as_string, $expected);
};

done_testing;
