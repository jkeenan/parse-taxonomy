# perl
# t/500-test-prep.t - verify presence of files needed for testing of
# Parse::File::Taxonomy::Index
use strict;
use warnings;
use Test::More tests => 1;

my @dummy = qw(
    bad_row_count.csv
    delta.csv
    duplicate_header_field.csv
    duplicate_id.csv
    epsilon.csv
    ids_missing_parents.csv
    nameless_component.csv
    sibling_same_name.csv
    zeta.csv
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

