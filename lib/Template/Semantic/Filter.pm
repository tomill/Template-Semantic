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

sub get_inner_html {
    my $node = shift;
    my $content = "";
    $content .= $_->serialize for $node->childNodes;
    $content;
}

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
    my $html = Template::Semantic::Filter::get_inner_html(shift);
    $html =~ s!(\r?\n)!<br />$1!g;
    \$html;
}

1;
