package t::TestBase;
use strict;
use warnings;
use Test::Base -base;
our @EXPORT = qw( run_template_process );

use Template::Semantic;

sub run_template_process {
    my %opt = @_;

    plan tests => 1 * blocks;
    
    filters {
        vars => [qw/ eval hash /],
    };

    my $ts = Template::Semantic->new;

    run {
        my $block = shift;
        my $doc = $ts->process(\$block->template, $block->vars);
        
        my $name = $block->name;
        if ($opt{selector_test}) {
            my ($selector)
                = $block->original_values->{vars} =~ /(.*?) =>/;
            $name .= ": $selector";
        }
        
        is($doc->as_string, $block->expected, $name);
    };
}

1;
