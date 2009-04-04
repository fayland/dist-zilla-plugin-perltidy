package Dist::Zilla::App::Command::perltidy;

use strict;
use warnings;

# ABSTRACT: perltidy your dist
use Dist::Zilla::App -command;

sub abstract {'perltidy your dist'}

sub run {
    my ( $self, $opt, $arg ) = @_;

    my $zilla = $self->zilla;

    # make Perl::Tidy happy
    local @ARGV = ();
    
    require Perl::Tidy;
    require File::Copy;
    require File::Next;
    require File::HomeDir;
    require File::Spec;
    
    my $config = { $self->config->flatten };
    print STDERR Dumper(\$config);
    
    my $rcfile;
    my $homerc = File::Spec->catfile( File::HomeDir->my_home, '.perltidyrc' );
    $rcfile = $homerc if -e $homerc;
    
    my $files = File::Next::files('.');
    while ( defined( my $file = $files->() ) ) {
        next unless ( $file =~ /\.(t|p[ml])$/ );    # perl file
        my $tidyfile = $file . '.tdy';
        Perl::Tidy::perltidy(
            source      => $file,
            destination => $tidyfile,
            perltidyrc  => '/home/fayland/git/foorum/bin/release/.perltidyrc',
        );
        File::Copy::move( $tidyfile, $file );
    }

    return 1;
}

1;
__END__


