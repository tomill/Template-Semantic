use strict;
use warnings;
use Test::More;

use Template::Semantic;

my $input = <<END
<div>
    <span>replace me</span>
    <textarea></textarea>
    <br/>
</div>
END
;

my $output = Template::Semantic->process(\$input, {
    'span' => 'HELLO WORLD',
});

isa_ok($output, 'Template::Semantic::Document');
isa_ok($output->dom, 'XML::LibXML::Document', '->dom()');

my $expected_as_xhtml = <<END
<div>
    <span>HELLO WORLD</span>
    <textarea></textarea>
    <br />
</div>
END
;

is("$output", $expected_as_xhtml, 'overload q{""}');

is($output->as_string, $expected_as_xhtml, '->as_string()');
is($output->as_string(is_xhtml => 1), $expected_as_xhtml, '->as_string(is_xhtml => 1)');

my $expected_as_xml = <<END
<div>
    <span>HELLO WORLD</span>
    <textarea/>
    <br/>
</div>
END
;

is($output->as_string(is_xhtml => 0), $expected_as_xml, '->as_string(is_xhtml => 0)');

done_testing;
