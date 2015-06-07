# perl
# t/501-new.t - Tests of Parse::File::Taxonomy::Index constructor
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::File::Taxonomy::Index;
use Test::More qw(no_plan); # tests => 20;
use Data::Dump;

my ($obj, $source, $expect);

{
    $source = "./t/data/epsilon.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new(
            file    => $source,
        );
    };
    like($@, qr/^Argument to 'new\(\)' must be hashref/,
        "new() died to lack of hashref as argument; was just a key-value pair");
}

{
    $source = "./t/data/epsilon.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( [
            file    => $source,
        ] );
    };
    like($@, qr/^Argument to 'new\(\)' must be hashref/,
        "new() died to lack of hashref as argument; was arrayref");
}

{
    $source = "./t/data/epsilon.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( { } );
    };
    like($@, qr/^Argument to 'new\(\)' must have 'file' element/,
        "new() died to lack of 'file' element in hashref passed as argument");
}

{
    $source = "./t/data/nonexistent.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
        } );
    };
    like($@, qr/^Cannot locate file '$source'/,
        "new() died due to inability to find source file '$source'");
}

{
    $source = "./t/data/duplicate_header_field.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
        } );
    };
    like($@, qr/^Duplicate field.*?observed in '$source'/,
        "new() died due to duplicate column name in source file '$source'");
}

{
    $source = "./t/data/delta.csv";
    local $@;
    $expect = 'my_id';
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
            id_col  => $expect,
        } );
    };
    like($@, qr/Could not locate columns in header to match required arguments.*id_col.*$expect/s,
        "new() died: id_col '$expect' not found in header row");
}

{
    $source = "./t/data/delta.csv";
    local $@;
    $expect = 'my_parent_id';
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
            parent_id_col  => $expect,
        } );
    };
    like($@, qr/Could not locate columns in header to match required arguments.*parent_id_col.*$expect/s,
        "new() died: parent_id_col '$expect' not found in header row");
}

{
    $source = "./t/data/delta.csv";
    local $@;
    $expect = 'my_name';
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
            component_col  => $expect,
        } );
    };
    like($@, qr/Could not locate columns in header to match required arguments.*component_col.*$expect/s,
        "new() died: component_col '$expect' not found in header row");
}

{
    $source = "./t/data/duplicate_id.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
        } );
    };

    like($@, qr/^No duplicate entries are permitted in the 'id'column./s,
        "new() died due to duplicate values in column designated as 'id_col'");
    like($@, qr/2:\s+2/s, "More than one column had 'id' of 2");
    like($@, qr/3:\s+2/s, "More than one column had 'id' of 3");
}

{
    $source = "./t/data/bad_row_count.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
        } );
    };

    like($@, qr/^Header row has \d+ columns.  The following records/s,
        "new() died due to wrong number of columns in one or more rows");
    like($@, qr/1:\s+7/s, "Identified record with too few columns");
    like($@, qr/4:\s+5/s, "Identified record with too few columns");
    like($@, qr/13:\s+10/s, "Identified record with too many columns");
}

{
    $source = "t/data/ids_missing_parents.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
        } );
    };
    like($@, qr/^For each record with a non-null value in the 'parent_id' column/s,
        "new() died due to parent_id column values without corresponding id records");
}

{
    $source = "t/data/sibling_same_name.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
        } );
    };
    like($@, qr/^No record with a non-null value in the 'parent_id' column/s,
        "new() died due to parent with children sharing same name");
}

{
    $source = "./t/data/delta.csv";
    note($source);
    $obj = Parse::File::Taxonomy::Index->new( {
        file    => $source,
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::File::Taxonomy::Index');

    # Tests of default values: replace once we have accessors
    $expect = $source;
    is($obj->{file}, $expect, "file: $expect");

    $expect = 'id';
    is($obj->{id_col}, $expect, "id_col: $expect");

    $expect = 'parent_id';
    is($obj->{parent_id_col}, $expect, "parent_id_col: $expect");

    $expect = 'name';
    is($obj->{component_col}, $expect, "component_col: $expect");

    # Move this to t/002-getters.t
    $expect = ["id","parent_id","name","vertical","currency_code","wholesale_price","retail_price","is_actionable"];
    is_deeply($obj->fields, $expect, "Got expected columns");
}

{
    $source = "./t/data/zeta.csv";
    note($source);
    $obj = Parse::File::Taxonomy::Index->new( {
        file                => $source,
        id_col              => 'my_id',
        parent_id_col       => 'my_parent_id',
        component_col       => 'my_name',
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::File::Taxonomy::Index');

    # Tests of default values: replace once we have accessors
    $expect = $source;
    is($obj->{file}, $expect, "file: $expect");

    $expect = 'my_id';
    is($obj->{id_col}, $expect, "id_col: $expect");

    $expect = 'my_parent_id';
    is($obj->{parent_id_col}, $expect, "parent_id_col: $expect");

    $expect = 'my_name';
    is($obj->{component_col}, $expect, "component_col: $expect");

    # Move this to t/002-getters.t
    $expect = ["my_id","my_parent_id","my_name","vertical","currency_code","wholesale_price","retail_price","is_actionable"];
    is_deeply($obj->fields, $expect, "Got expected columns");
}

