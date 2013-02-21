package Dist::Zilla::App::Command::perltidy;

use strict;
use warnings;

# ABSTRACT: perltidy your dist
use Dist::Zilla::App -command;

sub abstract {'perltidy your dist'}

sub execute {
    my ( $self, $opt, $arg ) = @_;

    # use perltidyrc from command line or from config
    my $perltidyrc;
    if ( scalar @$arg and -r $arg->[0] ) {
        $perltidyrc = $arg->[0];
    } else {
        my $plugin = $self->zilla->plugin_named('PerlTidy');
        if ( defined $plugin and defined $plugin->perltidyrc ) {
            $perltidyrc = $plugin->perltidyrc;
        }
    }

    # Verify that if a file is specified it is readable
    if ( defined $perltidyrc and not -r $perltidyrc ) {
        $self->zilla->log_fatal(
            [   "specified perltidyrc is not readable: %s ,\nNote: ~ and other shell expansions are not applicable",
                $perltidyrc
            ]
        );
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
        $self->zilla->log_debug(['Tidying %s', $file ]);
        if ( my $pid = fork() ){
            waitpid $pid, 0;
            $self->zilla->log_fatal(['Child exited with nonzero status: %s', $?]) if $? > 0;
            File::Copy::move( $tidyfile, $file );
            next;
        }
        Perl::Tidy::perltidy(
            source      => $file,
            destination => $tidyfile,
            ( $perltidyrc ? ( perltidyrc => $perltidyrc ) : () ),
        );
        exit 0;
    }

    return 1;
}

1;

=head2 SYNOPSIS

    $ dzil perltidy
    # OR
    $ dzil perltidy .myperltidyrc

=head2 CONFIGURATION

In your global dzil setting (which is '~/.dzil' or '~/.dzil/config.ini'),
you can config the perltidyrc like:

    [PerlTidy]
    perltidyrc = /home/fayland/somewhere/.perltidyrc


=head2 DEFAULTS

If you do not specify a specific perltidyrc in dist.ini it will try to use
the same defaults as Perl::Tidy.


=head2 SEE ALSO

L<Perl::Tidy>
