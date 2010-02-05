package Template::Semantic;
use strict;
use warnings;
our $VERSION = '0.01';

use Carp;
use XML::LibXML;
use Template::Semantic::Document;
use Template::Semantic::Filter;

sub new {
    my $class = shift;
    my $self  = bless { @_ }, $class;
    
    for (@Template::Semantic::Filter::EXPORT_OK) {
        $self->define_filter($_ => \&{'Template::Semantic::Filter::' . $_});
    }

    $self->{parser} ||= do {
        my $parser = XML::LibXML->new;
        $parser->no_network(1);
        $parser->recover(2); # It's mean "no warnings".
        $parser;
    };
    
    $self;
}

sub define_filter {
    my ($self, $name, $code) = @_;
    $self->{filter}{$name} ||= $code;
}

sub process {
    my $self = ref $_[0] ? shift : shift->new;
    my ($template, $vars) = @_;
    
    my $source;
    if (ref($template) eq 'SCALAR') {
        $source = $$template;
    } elsif (ref $template) {
        $source = do { local $/; <$template> };
    } else {
        open(my $fh, '<', $template) or croak $!;
        $source = do { local $/; <$fh> };
    }
    
    my $doc = Template::Semantic::Document->new(
        engine => $self,
        source => $source || "",
    );
    $doc->process($vars || {});
}

1;
__END__

=encoding utf-8

=head1 NAME

Template::Semantic -

=head1 SYNOPSIS

  use Template::Semantic;

=head1 DESCRIPTION

Template::Semantic is

please see t/*.t

とりあえず t/ 以下をみてちょうだい


=head1 METHODS

=over 4

=item new

=item foo

=back

=head1 SEE ALSO

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
