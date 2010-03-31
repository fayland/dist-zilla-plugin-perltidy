package Dist::Zilla::Plugin::PerlTidy;

# ABSTRACT: PerlTidy in Dist::Zilla

use Moose;
with 'Dist::Zilla::Role::FileMunger';

has 'perltidyrc' => ( is => 'rw' );

=method munge_file

Implements the required munge_file method for the
L<Dist::Zilla::Role::FileMunger> role, munging each Perl file it finds.
Files whose names do not end in C<.pm>, C<.pl>, or C<.t>, or whose contents
do not begin with C<#!perl> are left alone.

=cut

sub munge_file {
    my ( $self, $file ) = @_;

    return $self->_munge_perl($file) if $file->name    =~ /\.(?:pm|pl|t)$/i;
    return $self->_munge_perl($file) if $file->content =~ /^#!perl(?:$|\s)/;
    return;
}

sub _munge_perl {
    my ( $self, $file ) = @_;

    my $content = $file->content;

    my $perltidyrc;
    if ( $self->{perltidyrc} ) {
        if ( -e $self->{perltidyrc} ) {
            $perltidyrc = $self->{perltidyrc};
        } else {
            warn 'perltidyrc ' . $self->{perltidyrc} . " is not found\n";
        }
    }

    $perltidyrc ||= $ENV{PERLTIDYRC};

    # make Perl::Tidy happy
    local @ARGV = ();

    my $tided;
    require Perl::Tidy;
    Perl::Tidy::perltidy(
        source      => \$content,
        destination => \$tided,
        perltidyrc  => $perltidyrc,
    );

    $file->content($tided);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

=head1 SYNOPSIS

    # dist.ini
    [PerlTidy]

    # or
    [PerlTidy]
    perltidyrc = xt/.perltidyrc

=head2 perltidyrc

=head3 dist.ini

    [PerlTidy]
    perltidyrc = xt/.perltidyrc

=head3 ENV PERLTIDYRC

If you do not config like above, we will fall back to ENV PERLTIDYRC

    export PERLTIDYRC=/home/fayland/somwhere2/.perltidyrc
