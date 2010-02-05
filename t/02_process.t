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

subtest 'class->process()' => sub {
    plan tests => 1;

    my $output = Template::Semantic->process(\$input, {
        'span' => 'HELLO WORLD',
    });
    
    is($output, $expected);
};

subtest '$obj->process()' => sub {
    plan tests => 1;

    my $ts = Template::Semantic->new;
    my $output = $ts->process(\$input, {
        'span' => 'HELLO WORLD',
    });
    
    is($output, $expected);
};

subtest 'class->process()->process() chain' => sub {
    plan tests => 1;
    
    my $output = Template::Semantic->process(\$input, {
        'span' => 'hello world',
    })->process({
        'span' => sub { uc },
    });
    
    is($output, $expected);
};

subtest '$obj->process()->process() chain' => sub {
   plan tests => 1;
    

    my $ts = Template::Semantic->new;
    my $output = $ts->process(\$input, {
        'span' => 'hello world',
    })->process({
        'span' => sub { uc },
    });
    
    is($output, $expected);
};

done_testing;
