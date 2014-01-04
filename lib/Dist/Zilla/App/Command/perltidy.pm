package Dist::Zilla::App::Command::perltidy;

use strict;
use warnings;

# ABSTRACT: perltidy your dist
use Dist::Zilla::App -command;
use Path::Iterator::Rule;
use File::Copy;

sub abstract {'perltidy your dist'}

my $backends = {
    vanilla => sub {
        local @ARGV = ();
        require Perl::Tidy;
        return sub {
            local @ARGV = ();
            Perl::Tidy::perltidy(@_);
        };
    },
    sweet => sub {
        local @ARGV = ();
        require Perl::Tidy::Sweetened;
        return sub {
            local @ARGV = ();
            Perl::Tidy::Sweetened::perltidy(@_);
        };
    },
};

sub opt_spec {
    [ 'backend|b=s', 'tidy backend to use', { default => 'vanilla' } ];
}

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

    if ( not exists $backends->{ $opt->{backend} } ) {
        $self->zilla->log_fatal(
            [   "specified backend not known, known backends are: %s ",
                join q[,], sort keys %{$backends}
            ]
        );
    }

    my $tidy = $backends->{ $opt->{backend} }->();

# RT 91288
# copied from https://metacpan.org/source/KENTNL/Dist-Zilla-PluginBundle-Author-KENTNL-2.007000/utils/strip_eol.pl
    my $rule = Path::Iterator::Rule->new();
    $rule->skip_vcs;
    $rule->skip(
        sub {
            return if not -d $_;
            if ( $_[1] =~ qr/^\.build$/ ) {
                $self->zilla->log_debug('Ignoring .build');
                return 1;
            }
            if ( $_[1] =~ qr/^[A-Za-z].*-[0-9.]+(-TRIAL)?$/ ) {
                $self->zilla->log_debug('Ignoring dzil build tree');
                return 1;
            }
            return;
        }
    );
    $rule->file->nonempty;
    $rule->file->not_binary;

    # $rule->file->line_match(qr/\s\n/);

    my $next = $rule->iter(
        '.' => {
            follow_symlinks => 0,
            sorted          => 0,
        }
    );

    while ( my $file = $next->() ) {
        next unless ( $file =~ /\.(t|p[ml])$/ );    # perl file
        my $tidyfile = $file . '.tdy';
        $self->zilla->log_debug( [ 'Tidying %s', $file ] );
        if ( my $pid = fork() ) {
            waitpid $pid, 0;
            $self->zilla->log_fatal(
                [ 'Child exited with nonzero status: %s', $? ] )
                if $? > 0;
            File::Copy::move( $tidyfile, $file );
            next;
        }
        $tidy->(
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
