package Dist::Zilla::App::Command::perltidy;

use strict;
use warnings;

# ABSTRACT: perltidy your dist
use Dist::Zilla::App -command;

sub abstract {'perltidy your dist'}

sub run {
    my ( $self, $opt, $arg ) = @_;

    my $config = $self->config;
    my $perltidyrc = ( exists $config->{perltidyrc} and -e $config->{perltidyrc} ) ?
        $config->{perltidyrc} : undef;
    use Data::Dumper;
    print STDERR Dumper(\$config);

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


