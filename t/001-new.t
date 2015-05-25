# perl
# t/001-new.t - Tests of constructor
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::File::Taxonomy;
use Test::More qw(no_plan); # tests => 1;
use Data::Dump;

my ($obj, $source, $expect);

{
    $source = "./t/data/alpha.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy->new(
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
        $obj = Parse::File::Taxonomy->new( [
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
        $obj = Parse::File::Taxonomy->new( {
            file    => $source,
            rules => [
                sub { print "Hello World\n" },
                [ qw( a b c ) ],
            ],
        } );
    };
    like($@, qr/^Each element in 'rules' must be a code ref/,
        "'new()' died to non-coderef element in arrayref which is value of 'rules' argument");
}

{
    $source = "./t/data/alpha.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy->new( {
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
        $obj = Parse::File::Taxonomy->new( {
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
        $obj = Parse::File::Taxonomy->new( {
            rules => [ sub { print "Hello World\n" } ],
        } );
    };
    like($@, qr/^Argument to 'new\(\)' must have 'file' element/,
        "'new()' died to lack of 'file' element in hashref passed as argument");
}

{
    $source = "./t/data/nonexistent.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy->new( {
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
        $obj = Parse::File::Taxonomy->new( {
            file    => $source,
        } );
    };
    like($@, qr/^Duplicate field.*?observed in '$source'/,
        "'new()' died due to duplicate column name in source file '$source'");
}

{
    $source = "./t/data/duplicate_path.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy->new( {
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
    $source = "./t/data/missing_parents.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy->new( {
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
    $source = "./t/data/alpha.csv";
    $obj = Parse::File::Taxonomy->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::File::Taxonomy');

    $expect = [ "path","nationality","gender","age","income","id_no" ];
    my $fields = $obj->fields;
    is(ref($fields), 'ARRAY', "'fields' method returned an arrayref");
    is_deeply($fields, $expect, "Got expected arrayref of columns");

    $expect = 0;
    my $path_col_idx = $obj->path_col_idx;
    is($path_col_idx, $expect, "Column with index '$expect' is path column");

    $expect = 'path';
    my $path_col = $obj->path_col;
    is($path_col, $expect, "Path column is named '$expect'");

}

{
    $source = "./t/data/alt_path_col_sep.csv";
    $obj = Parse::File::Taxonomy->new( {
        file            => $source,
        path_col_sep    => ',',
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::File::Taxonomy');

    $expect = [ "path","nationality","gender","age","income","id_no" ];
    my $fields = $obj->fields;
    is(ref($fields), 'ARRAY', "'fields' method returned an arrayref");
    is_deeply($fields, $expect, "Got expected arrayref of columns");

    $expect = 0;
    my $path_col_idx = $obj->path_col_idx;
    is($path_col_idx, $expect, "Column with index '$expect' is path column");

    $expect = 'path';
    my $path_col = $obj->path_col;
    is($path_col, $expect, "Path column is named '$expect'");

}
