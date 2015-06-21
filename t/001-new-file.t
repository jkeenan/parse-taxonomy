# perl
# t/001-new-file.t - Tests of constructor's 'file' interface
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::Taxonomy::Path;
use Test::More qw(no_plan); # tests => 20;
use Scalar::Util qw( reftype );

my ($obj, $source, $fields, $data_records);

{
    $source = "./t/data/alpha.csv";
    local $@;
    eval {
        $obj = Parse::Taxonomy::Path->new(
            file    => $source,
        );
    };
    like($@, qr/^Argument to 'new\(\)' must be hashref/,
        "'new()' died to lack of hashref as argument; was just a key-value pair");
}

{
    $source = "./t/data/alpha.csv";
    local $@;
    eval {
        $obj = Parse::Taxonomy::Path->new( [
            file    => $source,
        ] );
    };
    like($@, qr/^Argument to 'new\(\)' must be hashref/,
        "'new()' died to lack of hashref as argument; was arrayref");
}

{
    $source = "./t/data/alpha.csv";
    local $@;
    eval {
        $obj = Parse::Taxonomy::Path->new( {
            file            => $source,
            path_col_idx    => 'path',
        } );
    };
    like($@, qr/^Argument to 'path_col_idx' must be integer/,
        "'new()' died due to non-integer value to 'path_col_idx'");
}

{
    $source = "./t/data/alpha.csv";
    local $@;
    eval {
        $obj = Parse::Taxonomy::Path->new( {
            file            => $source,
            path_col_idx    => 6,
        } );
    };
    like($@, qr/^Argument to 'path_col_idx' exceeds index of last field in header row in '$source'/,
        "'new()' died due to 'path_col_idx' higher than last index for array derived from header row");
}

{
    $source = "./t/data/alpha.csv";
    local $@;
    eval {
        $obj = Parse::Taxonomy::Path->new( { } );
    };
    like($@, qr/^Argument to 'new\(\)' must have either 'file' or 'components' element/,
        "'new()' died to lack of either 'file' or 'components' element in hashref passed as argument");
}

{
    $source = "./t/data/nonexistent.csv";
    local $@;
    eval {
        $obj = Parse::Taxonomy::Path->new( {
            file    => $source,
        } );
    };
    like($@, qr/^Cannot locate file '$source'/,
        "'new()' died due to inability to find source file '$source'");
}

{
    $source = "./t/data/duplicate_field.csv";
    local $@;
    eval {
        $obj = Parse::Taxonomy::Path->new( {
            file    => $source,
        } );
    };
    like($@, qr/^Duplicate field.*?observed in '$source'/,
        "'new()' died due to duplicate column name in source file '$source'");
}

{
    $source = "./t/data/reserved_field_names.csv";
    local $@;
    eval {
        $obj = Parse::Taxonomy::Path->new( {
            file    => $source,
        } );
    };
    for my $reserved ( qw| id parent_id name | ) {
        like($@, qr/^Bad column names: <.*\b$reserved\b.*>/,
            "'new()' died due to column named with reserved term '$reserved'");
    }
}

{
    $source = "./t/data/duplicate_path.csv";
    local $@;
    eval {
        $obj = Parse::Taxonomy::Path->new( {
            file    => $source,
        } );
    };
    like($@, qr/^No duplicate entries are permitted in column designated as path/s,
        "'new()' died due to duplicate values in column designated as 'path'");
    like($@, qr/\|Alpha\|Epsilon\|Kappa/s,
        "Duplicate path identified");
    like($@, qr/\|Gamma\|Iota/s,
        "Duplicate path identified");
}

{
    $source = "./t/data/wrong_row_count.csv";
    local $@;
    eval {
        $obj = Parse::Taxonomy::Path->new( {
            file    => $source,
        } );
    };

    like($@, qr/^Header row has \d+ records.  The following records had different counts:/s,
        "'new()' died due to wrong number of columns in one or more rows");
    like($@, qr/\|Alpha:\s+7/s, "Identified record with too many columns");
    like($@, qr/\|Alpha\|Epsilon:\s+5/s, "Identified record with too few columns");
}

{
    $source = "./t/data/missing_parents.csv";
    local $@;
    eval {
        $obj = Parse::Taxonomy::Path->new( {
            file    => $source,
        } );
    };
    like($@, qr/^Each node in the taxonomy must have a parent/s,
        "'new()' died due to entries in column designated as 'path' lacking parents");
    like($@, qr/\|Alpha\|Epsilon\|Kappa:\s+\|Alpha\|Epsilon/s,
        "Path lacking parent identified");
    like($@, qr/\|Gamma\|Iota\|Nu:\s+\|Gamma\|Iota/s,
        "Duplicate path identified");
}

{
    $source = "./t/data/path_sibling_same_name.csv";
    local $@;
    eval {
        $obj = Parse::Taxonomy::Path->new( {
            file    => $source,
        } );
    };
    like($@, qr/^No duplicate entries are permitted in column designated as path/s,
        "'new()' died due to duplicate values in column designated as 'path'");
    like($@, qr/\|Alpha\|Epsilon\|Kappa/s,
        "Duplicate path identified");
}

{
    $source = "./t/data/alpha.csv";
    note($source);
    $obj = Parse::Taxonomy::Path->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::Path');

}

{
    $source = "./t/data/alt_path_col_sep.csv";
    note($source);
    $obj = Parse::Taxonomy::Path->new( {
        file            => $source,
        path_col_sep    => ',',
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::Path');

}

