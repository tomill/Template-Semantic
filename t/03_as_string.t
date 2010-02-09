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

my $output = Template::Semantic->process(\$input, {
    'span' => 'HELLO WORLD',
});

isa_ok($output, 'Template::Semantic::Document');
isa_ok($output->dom, 'XML::LibXML::Document', '->dom()');

is("$output", $expected, 'overload q{""}');
is($output->as_string, $expected, '->as_string()');

done_testing;
