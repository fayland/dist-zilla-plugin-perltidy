package Dist::Zilla::Plugin::PerlTidy;

# ABSTRACT: PerlTidy in Dist::Zilla

use Moose;
with 'Dist::Zilla::Role::FileMunger';

has 'perltidyrc' => ( is => 'ro' );

=method munge_file

Implements the required munge_file method for the
L<Dist::Zilla::Role::FileMunger> role, munging each Perl file it finds.
Files whose names do not end in C<.pm>, C<.pl>, or C<.t>, or whose contents
do not begin with C<#!perl> are left alone.

=cut

sub munge_file {
    my ( $self, $file ) = @_;

    return $self->_munge_perl($file) if $file->name =~ /\.(?:pm|pl|t)$/i;
    return if -B $file->name; # do not try to read binary file
    return $self->_munge_perl($file) if $file->content =~ /^#!perl(?:$|\s)/;
    return;
}

sub _munge_perl {
    my ( $self, $file ) = @_;

    return if ref($file) eq 'Dist::Zilla::File::FromCode';
    my $source = $file->content;

    my $perltidyrc;
    if ( defined $self->perltidyrc ) {
        if ( -r $self->perltidyrc ) {
            $perltidyrc = $self->perltidyrc;
        } else {
            $self->log_fatal(
                [ "specified perltidyrc is not readable: %s", $perltidyrc ] );
        }
    }

    # make Perl::Tidy happy
    local @ARGV = ();

    my $destination;
    require Perl::Tidy;
    Perl::Tidy::perltidy(
        source      => \$source,
        destination => \$destination,
        ( $perltidyrc ? ( perltidyrc => $perltidyrc ) : () ),
    );

    $file->content($destination);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=head2 SYNOPSIS

    # dist.ini
    [PerlTidy]

    # or
    [PerlTidy]
    perltidyrc = xt/.perltidyrc


=head2 DEFAULTS

If you do not specify a specific perltidyrc in dist.ini it will try to use
the same defaults as Perl::Tidy.


=head2 SEE ALSO

L<Perl::Tidy>
