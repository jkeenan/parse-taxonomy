# perl
# t/000-test-prep.t - verify presence of files needed for testing
use strict;
use warnings;
use Test::More tests => 1;

my @dummy = qw(
    alpha.csv
    duplicate_field.csv
);

my %seen_bad;
for my $f (@dummy) {
    my $path = "./t/data/$f";
    $seen_bad{$path}++ unless (-f $path);
}
is(scalar(keys(%seen_bad)), 0,
    "Found all dummy data files needed for testing")
    or diag("Could not locate: " .
        join(' ' => sort keys %seen_bad)
);

