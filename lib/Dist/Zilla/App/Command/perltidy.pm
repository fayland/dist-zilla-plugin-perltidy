package Dist::Zilla::App::Command::perltidy;

use strict;
use warnings;

# ABSTRACT: perltidy your dist
use Dist::Zilla::App -command;

sub abstract { 'perltidy your dist' }

sub run {
    my ( $self, $opt, $arg ) = @_;

    my $perltidyrc;
    if ( scalar @$arg and -e $arg->[0] ) {
        $perltidyrc = $arg->[0];
    } else {
        my $config = $self->app->config_for('Dist::Zilla::Plugin::PerlTidy');
        $perltidyrc = ( exists $config->{perltidyrc} and -e $config->{perltidyrc} ) ?
            $config->{perltidyrc} : undef;
    }

    # make Perl::Tidy happy
    local @ARGV = ();

    require Perl::Tidy;
    require File::Copy;
    require File::Next;

    my $files = File::Next::files('.');
    while ( defined( my $file = $files->() ) ) {
        next unless ( $file =~ /\.(t|p[ml])$/ );    # perl file
        my $tidyfile = $file . '.tdy';
        Perl::Tidy::perltidy(
            source      => $file,
            destination => $tidyfile,
            perltidyrc  => $perltidyrc,
        );
        File::Copy::move( $tidyfile, $file );
    }

    return 1;
}

1;
__END__

=head1 NAME

Dist::Zilla::App::Command::perltidy - perltidy a dist

=head1 SYNOPSIS

    $ dzil perltidy
    # OR
    $ dzil perltidy .myperltidyrc

=head1 CONFIG

In your global dzil setting (which is '~/.dzil' or '~/.dzil/config'), you can config the
 perltidyrc file like:

    [PerlTidy]
    perltidyrc = /home/fayland/somewhere/.perltidyrc

=head1 AUTHOR

Fayland Lam, C<< E<lt>fayland@gmail.comE<gt> >>

=head1 COPYRIGHT

Copyright 2008, Fayland Lam.

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.
