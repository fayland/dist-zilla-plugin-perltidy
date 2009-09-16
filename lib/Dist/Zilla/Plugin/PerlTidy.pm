package Dist::Zilla::Plugin::PerlTidy;

# ABSTRACT: PerlTidy in Dist::Zilla

use Moose;
with 'Dist::Zilla::Role::FileMunger';

has 'perltidyrc' => ( is => 'rw' );

sub munge_file {
    my ( $self, $file ) = @_;

    return $self->munge_perl($file) if $file->name    =~ /\.(?:pm|pl|t)$/i;
    return $self->munge_perl($file) if $file->content =~ /^#!perl(?:$|\s)/;
    return;
}

sub munge_perl {
    my ( $self, $file ) = @_;

    my $content = $file->content;

    my $perltidyrc;
    if ( $self->{perltidyrc} ) {
        if ( -e $self->{perltidyrc} ) {
            $perltidyrc = $self->{perltidyrc};
        } else {
            warn 'perltidyrc ' . $self->{perltidyrc} . " is not found\n";
        }
    } elsif ( my $config =
        $self->zilla->dzil_app->config_for('Dist::Zilla::Plugin::PerlTidy') ) {
        if ( exists $config->{perltidyrc} ) {
            if ( -e $config->{perltidyrc} ) {
                $perltidyrc = $config->{perltidyrc};
            } else {
                warn "perltidyrc $config->{perltidyrc} is not found\n";
            }
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
__END__

=head1 NAME

Dist::Zilla::Plugin::PerlTidy - PerlTidy in Dist::Zilla

=head1 SYNOPSIS

    # dist.ini
    [PerlTidy]

    # or
    [PerlTidy]
    perltidyrc = xt/.perltidyrc

=head1 perltidyrc

=head2 dist.ini

    [PerlTidy]
    perltidyrc = xt/.perltidyrc

=head2 dzil config

In your global dzil setting (which is '~/.dzil' or '~/.dzil/config'), you can config the
 perltidyrc like:

    [PerlTidy]
    perltidyrc = /home/fayland/somewhere/.perltidyrc

=head2 ENV PERLTIDYRC

If you do not config like above, we will fall back to ENV PERLTIDYRC

    export PERLTIDYRC=/home/fayland/somwhere2/.perltidyrc

=head1 AUTHOR

Fayland Lam, C<< E<lt>fayland@gmail.comE<gt> >>

=head1 COPYRIGHT

Copyright 2009, Fayland Lam.

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.
