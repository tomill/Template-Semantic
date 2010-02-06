package Template::Semantic::Filter;
use strict;
use warnings;
use Carp;
use base 'Exporter';

our @EXPORT_OK = qw(
    chomp
    trim
    sort
    uniq
    comma
    html_line_break
);

sub chomp {
    chomp;
    $_;
}

sub trim {
    s/^ *| *$//g;
    $_;
}

sub sort {
    join " ", sort split /\s+/;
}

sub uniq {
    my %h;
    join " ", map { $h{$_}++ == 0 ? $_ : () } split /\s+/;
}

# from: Template::Plugin::Comma
sub comma {
   1 while s/((?:\A|[^.0-9])[-+]?\d+)(\d{3})/$1,$2/s;
   $_;
}

# from: Template::Filters
sub html_line_break {
    s!(\r?\n)!<br />$1!g;
    \$_;
}

1;
