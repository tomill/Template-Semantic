package Template::Semantic::Filter;
use strict;
use warnings;
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

sub comma {
   1 while s/((?:\A|[^.0-9])[-+]?\d+)(\d{3})/$1,$2/s;
   $_;
}

sub html_line_break {
    s!(\r?\n)!<br />$1!g;
    \$_;
}

1;
__END__

=head1 NAME

Template::Semantic::Filter - Template::Semantic Defined filters

=head1 FILTERS

=head2 chomp

  $ts->process($template, {
      'h1' => [ "foo\n", 'chomp' ], # => <h1>foo</h1>
  })

=head2 trim

  $ts->process($template, {
      'h1' => [ " foo ", 'trim' ], # => <h1>foo</h1>
  })

=head2 sort

  $ts->process($template, {
      'h1@class' => [ "zzz xxx yyy", 'sort' ], # => <h1 class="xxx yyy zzz">foo</h1>
  })

=head2 uniq

  $ts->process($template, {
      'h1@chass' => [ "foo bar foo", 'uniq' ], # => <h1 class="foo bar">foo</h1>
  })

=head2 comma

  $ts->process($template, {
      'h1' => [ "10000", 'comma' ], # => <h1>10,000</h1>
  })

codes from: L<Template::Plugin::Comma>.

=head2 html_line_break

  $ts->process($template, {
      'p' => [ "foo & foo\nbar\n", 'html_line_break' ],
      # =>
      # <p>foo &amp; foo<br />
      # bar <br /></p>
  })

codes from: L<Template::Filters>C<::html_line_break()>.

=head1 SEE ALSO

L<Template::Semantic>

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=cut
