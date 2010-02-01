use strict;
use warnings;
use Test::More;

use Template::Semantic;

my $text = <<END
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

subtest 'scalar ref' => sub {
    plan tests => 1;

    my $ts = Template::Semantic->new;
    my $output = $ts->process(\$text, {
        'span' => 'HELLO WORLD',
    });
    
    is($output, $expected);
};

subtest 'file handle' => sub {
    plan tests => 1;
    
    open(my $fh, '<', 't/01_load-template.xml') or die $!;

    my $ts = Template::Semantic->new;
    my $output = $ts->process($fh, {
        'span' => 'HELLO WORLD',
    });
    
    is($output, $expected);
};

subtest 'file' => sub {
    plan tests => 1;

    my $ts = Template::Semantic->new;
    my $output = $ts->process('t/01_load-template.xml', {
        'span' => 'HELLO WORLD',
    });
    
    is($output, $expected);
};

done_testing;
