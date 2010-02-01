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

subtest '$obj->process( optional params )' => sub {
    plan tests => 1;
    
    use XML::LibXML;
    my $ts = Template::Semantic->new(
        parser => do {
            my $parser = XML::LibXML->new;
            $parser->no_network(1);
            $parser->recover(0);
            $parser;
        },
    );
    
    eval {
        $ts->process(\'<root>&heart;</root>');
    };
    like($@, qr/Entity 'heart' not defined/);
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
