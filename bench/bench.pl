use strict;
use warnings;
use Benchmark;

use HTML::Template;
use Template::Semantic;
use Template;
use Text::MicroTemplate::File;

Benchmark::cmpthese( -1, {
    'Template-Toolkit' => sub {
        my $tt = Template->new;
        $tt->process('bench/tt.html', {
            'title' => 'foo & bar',
            'list' => [
                { 'name' => 'aaa', 'count' => '001' },
                { 'name' => 'aaa', 'count' => '002' },
                { 'name' => 'aaa', 'count' => '003' },
            ],
        }, \my $out);
    },
    
    'Template::Semantic' => sub {
        my $out = Template::Semantic->process('bench/ts.html', {
            'title, h1' => 'foo & bar',
            'table.list tr' => [
                { '.name' => 'aaa', '.count' => '001' },
                { '.name' => 'aaa', '.count' => '002' },
                { '.name' => 'aaa', '.count' => '003' },
            ],
        });
        my $r = $out->as_string;
    },
    
    'HTML::Template' => sub {
        my $ht = HTML::Template->new(filename => 'bench/ht.html');
        $ht->param('title' => 'foo & bar');
        $ht->param('list' => [
                { 'name' => 'aaa', 'count' => '001' },
                { 'name' => 'aaa', 'count' => '002' },
                { 'name' => 'aaa', 'count' => '003' },
        ]);
        my $r = $ht->output;
    },

    'Text::MicroTemplate' => sub {
        my $tm = Text::MicroTemplate::File->new;
        my $out = $tm->render_file('bench/tm.html', {
            'title' => 'foo & bar',
            'list' => [
                { 'name' => 'aaa', 'count' => '001' },
                { 'name' => 'aaa', 'count' => '002' },
                { 'name' => 'aaa', 'count' => '003' },
            ],
        });
        my $r = $out->as_string;
    },
});
