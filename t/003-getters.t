# perl
# t/002-getters.t - Tests of methods which get data out of object
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::Taxonomy::MaterializedPath;
use Test::More tests => 72;

my ($obj, $source, $expect);

{
    $source = "./t/data/alpha.csv";
    note($source);
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

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

    $expect = '|';
    my $path_col_sep = $obj->path_col_sep;
    is($path_col_sep, $expect, "Path column separator is '$expect'");

    my $data_records = $obj->data_records;
    is(ref($data_records), "ARRAY", "data_records() returned arrayref");
    my $is_array_ref = 1;
    for my $row (@{$data_records}) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each row returned by data_records() is an array ref");
    my $path_record_well_formed = 1;
    for my $row (@{$data_records}) {
        my $path_component_count = grep { m/\Q$path_col_sep\E/ } $row->[$path_col_idx];
        if (! $path_component_count) {
            $path_record_well_formed = 0;
            last;
        }
    }
    ok($path_record_well_formed,
        "The path record in each row has expected path column separator ('$path_col_sep')");

    my $fields_and_data_records = $obj->fields_and_data_records();
    is_deeply($fields_and_data_records->[0], $fields,
        "First row in output of fields_and_data_records() appears to be taxonomy header");
    $is_array_ref = 1;
    for my $row (@{$fields_and_data_records}[1..$#{$fields_and_data_records}]) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each data row returned by fields_and_data_records() is an array ref");
    $path_record_well_formed = 1;
    for my $row (@{$fields_and_data_records}[1..$#{$fields_and_data_records}]) {
        my $path_component_count = grep { m/\Q$path_col_sep\E/ } $row->[$path_col_idx];
        if (! $path_component_count) {
            $path_record_well_formed = 0;
            last;
        }
    }
    ok($path_record_well_formed,
        "The path record in each data row has expected path column separator ('$path_col_sep')");

    my $data_records_path_components = $obj->data_records_path_components;
    is(ref($data_records_path_components), "ARRAY", "data_records_path_components() returned arrayref");
    $is_array_ref = 1;
    for my $row (@{$data_records_path_components}) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each row returned by data_records_path_components() is an array ref");
    $is_array_ref = 1;
    for my $row (@{$data_records_path_components}) {
        if (ref($data_records_path_components->[$obj->{path_col_idx}]) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref,
        "Path column in each row returned by data_records_path_components() is now an array ref");

    my $fields_and_data_records_path_components = $obj->fields_and_data_records_path_components();
    is(ref($fields_and_data_records_path_components), "ARRAY",
        "fields_and_data_records_path_components() returned arrayref");
    is_deeply($fields_and_data_records_path_components->[0], $fields,
        "First row in output of fields_and_data_records_path_components() appears to be taxonomy header");
    $is_array_ref = 1;
    for my $row (@{$fields_and_data_records_path_components}[1..$#{$fields_and_data_records_path_components}]) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each data row returned by fields_and_data_records_path_components() is an array ref");
    $is_array_ref = 1;
    for my $row (@{$fields_and_data_records_path_components}) {
        if (ref($fields_and_data_records_path_components->[$obj->{path_col_idx}]) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref,
        "Path column in each row returned by fields_and_data_records_path_components() is now an array ref");

    $expect = {
      "|Alpha"               => 5,
      "|Alpha|Epsilon"       => 1,
      "|Alpha|Epsilon|Kappa" => 0,
      "|Alpha|Zeta"          => 2,
      "|Alpha|Zeta|Lambda"   => 0,
      "|Alpha|Zeta|Mu"       => 0,
      "|Beta"                => 2,
      "|Beta|Eta"            => 0,
      "|Beta|Theta"          => 0,
      "|Delta"               => 0,
      "|Gamma"               => 2,
      "|Gamma|Iota"          => 1,
      "|Gamma|Iota|Nu"       => 0,
    };
    my $descendant_counts = $obj->descendant_counts();
    is_deeply($descendant_counts, $expect, "Got expected descendant count for each node");

    my $child_counts = $obj->child_counts();
    is_deeply($child_counts, $expect, "Got expected child count for each node");


    {
        my ($n, $node_descendant_count);

        local $@;
        $n = 'foo';
        eval { $node_descendant_count = $obj->get_descendant_count($n); };
        like($@, qr/Node '$n' not found/,
            "Argument '$n' to 'get_descendant_count' is not a node");
        local $@;

        $n = '|Gamma';
        $expect = 2;
        $node_descendant_count = $obj->get_descendant_count($n);
        is($node_descendant_count, $expect, "Node with $expect descendants found");

        $n = '|Gamma|Iota|Nu';
        $expect = 0;
        $node_descendant_count = $obj->get_descendant_count($n);
        is($node_descendant_count, $expect, "Node with $expect descendants -- leaf node -- found");
    }

    {
        my ($n, $node_child_count);

        local $@;
        $n = 'foo';
        eval { $node_child_count = $obj->get_child_count($n); };
        like($@, qr/Node '$n' not found/,
            "Argument '$n' to 'get_child_count' is not a node");
        local $@;

        $n = '|Gamma';
        $expect = 2;
        $node_child_count = $obj->get_child_count($n);
        is($node_child_count, $expect, "Node with $expect descendants found");

        $n = '|Gamma|Iota|Nu';
        $expect = 0;
        $node_child_count = $obj->get_child_count($n);
        is($node_child_count, $expect, "Node with $expect descendants -- leaf node -- found");
    }

    {
        $expect = 4;
        is($obj->get_field_position('income'), $expect,
            "'income' found in position $expect as expected");
        local $@;
        my $bad_field = 'foo';
        eval { $obj->get_field_position($bad_field); };
        like($@, qr/'$bad_field' not a field in this taxonomy/,
            "get_field_position() threw exception due to non-existent field");
    }

} 

{
    $source = "./t/data/alt_path_col_sep.csv";
    note($source);
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file            => $source,
        path_col_sep    => ',',
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

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

    $expect = ',';
    my $path_col_sep = $obj->path_col_sep;
    is($path_col_sep, $expect, "Path column separator is '$expect'");
}

{
    note("'components' interface");
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        components => {
            fields          => ["path","nationality","gender","age","income","id_no"],
            data_records    => [
              ["|Alpha","","","","",""],
              ["|Alpha|Epsilon","","","","",""],
              ["|Alpha|Epsilon|Kappa","","","","",""],
              ["|Alpha|Zeta","","","","",""],
              ["|Alpha|Zeta|Lambda","","","","",""],
              ["|Alpha|Zeta|Mu","","","","",""],
              ["|Beta","","","","",""],
              ["|Beta|Eta","","","","",""],
              ["|Beta|Theta","","","","",""],
              ["|Gamma","","","","",""],
              ["|Gamma|Iota","","","","",""],
              ["|Gamma|Iota|Nu","","","","",""],
              ["|Delta","","","","",""],
            ],
        },
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

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

    $expect = '|';
    my $path_col_sep = $obj->path_col_sep;
    is($path_col_sep, $expect, "Path column separator is '$expect'");

    my $data_records = $obj->data_records;
    is(ref($data_records), "ARRAY", "data_records() returned arrayref");
    my $is_array_ref = 1;
    for my $row (@{$data_records}) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each row returned by data_records() is an array ref");
    my $path_record_well_formed = 1;
    for my $row (@{$data_records}) {
        my $path_component_count = grep { m/\Q$path_col_sep\E/ } $row->[$path_col_idx];
        if (! $path_component_count) {
            $path_record_well_formed = 0;
            last;
        }
    }
    ok($path_record_well_formed,
        "The path record in each row has expected path column separator ('$path_col_sep')");

    my $fields_and_data_records = $obj->fields_and_data_records();
    is_deeply($fields_and_data_records->[0], $fields,
        "First row in output of fields_and_data_records() appears to be taxonomy header");
    $is_array_ref = 1;
    for my $row (@{$fields_and_data_records}[1..$#{$fields_and_data_records}]) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each data row returned by fields_and_data_records() is an array ref");
    $path_record_well_formed = 1;
    for my $row (@{$fields_and_data_records}[1..$#{$fields_and_data_records}]) {
        my $path_component_count = grep { m/\Q$path_col_sep\E/ } $row->[$path_col_idx];
        if (! $path_component_count) {
            $path_record_well_formed = 0;
            last;
        }
    }
    ok($path_record_well_formed,
        "The path record in each data row has expected path column separator ('$path_col_sep')");

    my $data_records_path_components = $obj->data_records_path_components;
    is(ref($data_records_path_components), "ARRAY", "data_records_path_components() returned arrayref");
    $is_array_ref = 1;
    for my $row (@{$data_records_path_components}) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each row returned by data_records_path_components() is an array ref");
    $is_array_ref = 1;
    for my $row (@{$data_records_path_components}) {
        if (ref($data_records_path_components->[$obj->{path_col_idx}]) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref,
        "Path column in each row returned by data_records_path_components() is now an array ref");

    my $fields_and_data_records_path_components = $obj->fields_and_data_records_path_components();
    is(ref($fields_and_data_records_path_components), "ARRAY",
        "fields_and_data_records_path_components() returned arrayref");
    is_deeply($fields_and_data_records_path_components->[0], $fields,
        "First row in output of fields_and_data_records_path_components() appears to be taxonomy header");
    $is_array_ref = 1;
    for my $row (@{$fields_and_data_records_path_components}[1..$#{$fields_and_data_records_path_components}]) {
        if (ref($row) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref, "Each data row returned by fields_and_data_records_path_components() is an array ref");
    $is_array_ref = 1;
    for my $row (@{$fields_and_data_records_path_components}) {
        if (ref($fields_and_data_records_path_components->[$obj->{path_col_idx}]) ne 'ARRAY') {
            $is_array_ref = 0;
            last;
        }
    }
    ok($is_array_ref,
        "Path column in each row returned by fields_and_data_records_path_components() is now an array ref");

    $expect = {
      "|Alpha"               => 5,
      "|Alpha|Epsilon"       => 1,
      "|Alpha|Epsilon|Kappa" => 0,
      "|Alpha|Zeta"          => 2,
      "|Alpha|Zeta|Lambda"   => 0,
      "|Alpha|Zeta|Mu"       => 0,
      "|Beta"                => 2,
      "|Beta|Eta"            => 0,
      "|Beta|Theta"          => 0,
      "|Delta"               => 0,
      "|Gamma"               => 2,
      "|Gamma|Iota"          => 1,
      "|Gamma|Iota|Nu"       => 0,
    };
    my $descendant_counts = $obj->descendant_counts();
    is_deeply($descendant_counts, $expect, "Got expected descendant count for each node");

    my $child_counts = $obj->child_counts();
    is_deeply($child_counts, $expect, "Got expected child count for each node");


    {
        my ($n, $node_descendant_count);

        local $@;
        $n = 'foo';
        eval { $node_descendant_count = $obj->get_descendant_count($n); };
        like($@, qr/Node '$n' not found/,
            "Argument '$n' to 'get_descendant_count' is not a node");
        local $@;

        $n = '|Gamma';
        $expect = 2;
        $node_descendant_count = $obj->get_descendant_count($n);
        is($node_descendant_count, $expect, "Node with $expect descendants found");

        $n = '|Gamma|Iota|Nu';
        $expect = 0;
        $node_descendant_count = $obj->get_descendant_count($n);
        is($node_descendant_count, $expect, "Node with $expect descendants -- leaf node -- found");
    }

    {
        my ($n, $node_child_count);

        local $@;
        $n = 'foo';
        eval { $node_child_count = $obj->get_child_count($n); };
        like($@, qr/Node '$n' not found/,
            "Argument '$n' to 'get_child_count' is not a node");
        local $@;

        $n = '|Gamma';
        $expect = 2;
        $node_child_count = $obj->get_child_count($n);
        is($node_child_count, $expect, "Node with $expect descendants found");

        $n = '|Gamma|Iota|Nu';
        $expect = 0;
        $node_child_count = $obj->get_child_count($n);
        is($node_child_count, $expect, "Node with $expect descendants -- leaf node -- found");
    }
} 

{
    note("'components' interface; alternate path_col_sep");
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        components => {
            fields          => ["path","nationality","gender","age","income","id_no"],
            data_records    => [
              [",Alpha","","","","",""],
              [",Alpha,Epsilon","","","","",""],
              [",Alpha,Epsilon,Kappa","","","","",""],
              [",Alpha,Zeta","","","","",""],
              [",Alpha,Zeta,Lambda","","","","",""],
              [",Alpha,Zeta,Mu","","","","",""],
              [",Beta","","","","",""],
              [",Beta,Eta","","","","",""],
              [",Beta,Theta","","","","",""],
              [",Gamma","","","","",""],
              [",Gamma,Iota","","","","",""],
              [",Gamma,Iota,Nu","","","","",""],
              [",Delta","","","","",""],
            ],
        },
        path_col_sep    => ',',
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

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

    $expect = ',';
    my $path_col_sep = $obj->path_col_sep;
    is($path_col_sep, $expect, "Path column separator is '$expect'");
}


