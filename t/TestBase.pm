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
        vars  => [qw/ eval hash /],
        error => [qw/ regexp /],
    };

    my $ts = Template::Semantic->new;

    run {
        my $block = shift;
        
        my $out;
        eval {
            $out = $ts->process(\$block->template, $block->vars);
        };
        
        if ($@) {
            if ($block->error) {
                like($@, $block->error, $block->name);
            } else {
                is($@, "", $block->name);
            }
        } else {
            my $name = $block->name;
            if ($opt{selector_test}) {
                my ($selector)
                    = $block->original_values->{vars} =~ /(.*?) =>/;
                $name .= ": $selector";
            }
            
            is($out->as_string, $block->expected, $name);
        }
    };
}

1;
