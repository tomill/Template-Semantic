use strict;
use warnings;
use Test::More;

use Template::Semantic;

subtest 'xinclude' => sub {
    plan tests => 2;
    
    my $input = q{<?xml version="1.0"?>
    <root xmlns:xi="http://www.w3.org/2001/XInclude">
        <body>
            <xi:include href="t/10_xinclude.xml" parse="xml"/>
        </body>
    </root>};

    my $ts = Template::Semantic->new( expand_xinclude => 1 );
    my $out = $ts->process(\$input, {
        '#foo' => 'xxx',
        '.bar' => 'xxx',
    })->process({
        '@xml:base' => undef,
    });
    
    like($out, qr{<div id="foo">xxx</div>});
    like($out, qr{<div class="bar">xxx</div>});
};

subtest 'dynamic xinclude?' => sub {
    plan skip_all => 'not implemented';
    
    my $input = q{<?xml version="1.0"?>
    <root xmlns:xi="http://www.w3.org/2001/XInclude">
        <body>
            <xi:include href="" parse="xml" id="include"/>
        </body>
    </root>};

    my $ts = Template::Semantic->new( expand_xinclude => 1 );
    my $out = $ts->process('t/10_xinclude.xml', {
        '#inc@src' => 't/10_xinclude.xml',
    })->process({
        '#foo' => 'xxx',
        '.bar' => 'xxx',
    });

    like($out, qr{<div id="foo">xxx</div>});
    like($out, qr{<div class="bar">xxx</div>});
};

done_testing;
