package ExtUtils::ExtractVersion;
require 5.006;
use strict;

use Exporter (); BEGIN { *import = \&Exporter::import }

our @EXPORT_OK = qw(extract_version);

sub extract_version {
    my ($parsefile) = @_;
    my $result;

    local $/ = "\n";
    local $_;
    open(my $fh, '<', $parsefile) or die "Could not open '$parsefile': $!";
    my $inpod = 0;
    while (<$fh>) {
        $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
        next if $inpod || /^\s*#/;
        chop;
        next if /^\s*(if|unless|elsif)/;
        if ( m{^ \s* package \s+ \w[\w\:\']* \s+ (v?[0-9._]+) \s* (;|\{)  }x ) {
            local $^W = 0;
            $result = $1;
        }
        elsif ( m{(?<!\\) ([\$*]) (([\w\:\']*) \bVERSION)\b .* (?<![<>=!])\=[^=]}x ) {
            $result = _get_version($parsefile, $1, $2);
        }
        else {
            next;
        }
        last if defined $result;
    }
    close $fh;

    if ( defined $result && $result !~ /^v?[\d_\.]+$/ ) {
        require version;
        my $normal = eval { version->new( $result ) };
        $result = $normal if defined $normal;
    }
    $result = "undef" unless defined $result;
    return $result;
}

sub _get_version {
    my ($parsefile, $sigil, $name) = @_;
    my $line = $_; # from the while() loop in parse_version
    {
        package ExtUtils::MakeMaker::_version;
        undef *version; # in case of unexpected version() sub
        eval {
            require version;
            version::->import;
        };
        no strict;
        local *{$name};
        local $^W = 0;
        $line = $1 if $line =~ m{^(.+)}s;
        eval($line); ## no critic
        return ${$name};
    }
}

1;
__END__

=head1 NAME

ExtUtils::ExtractVersion - Extract a version number from a file

=head1 SYNOPSIS

    use ExtUtils::ExtractVersion qw(extract_version);
    my $version = parse_version($file);

=head1 DESCRIPTION

Extract a version number from a file.

=head1 FUNCTIONS

=head2 extract_version

    my $version = extract_version($file);

Parse a $file and return what $VERSION is set to by the first assignment.
It will return the string "undef" if it can't figure out what $VERSION
is. $VERSION should be for all to see, so C<our $VERSION> or plain $VERSION
are okay, but C<my $VERSION> is not.

C<< package Foo VERSION >> is also checked for.  The first version
declaration found is used, but this may change as it differs from how
Perl does it.

extract_version() will try to C<use version> before checking for
C<$VERSION> so the following will work.

    $VERSION = qv(1.2.3);

=cut
