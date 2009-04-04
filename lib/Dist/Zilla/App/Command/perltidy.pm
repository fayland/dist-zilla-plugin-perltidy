package Dist::Zilla::App::Command::perltidy;

use strict;
use warnings;

# ABSTRACT: perltidy your dist
use Perl::Tidy;
use Dist::Zilla::App -command;

sub abstract {'perltidy your dist'}

sub run {
    my $self = shift;
    my $opt  = shift;
    my $arg  = shift;

    local @ARGV = ();

    require File::Copy;
    require File::Next;
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


