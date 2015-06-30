# perl
# t/005-adjacentify.t
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::Taxonomy::MaterializedPath;
use Test::More qw(no_plan); # tests => 15;
use List::Util qw( min );
use Cwd;
use File::Temp qw/ tempdir /;

my ($obj, $source, $expect, $adjacentified);

{
    $source = "./t/data/beta.csv";
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    local $@;
    eval {
        $adjacentified = $obj->adjacentify(
            serial => 500,
        );
    };
    like($@, qr/^Argument to 'adjacentify\(\)' must be hashref/,
        "'adjacentify()' died to lack of hashref as argument; was just a key-value pair");

    local $@;
    eval {
        $adjacentified = $obj->adjacentify( [
            serial => 500,
        ] );
    };
    like($@, qr/^Argument to 'adjacentify\(\)' must be hashref/,
        "'adjacentify()' died to lack of hashref as argument; was arrayref");
}

{
    $source = "./t/data/beta.csv";
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    note("adjacentify()");
    $adjacentified = $obj->adjacentify();
    ok($adjacentified, "'adjacentify() returned true value");
    my @ids_seen = map { $_->{id} } @{$adjacentified};
    is(min(@ids_seen), 1,
        "Lowest 'id' value is 1, as serial defaults to 0");

    note("write_adjacentified_to_csv()");
    my $csv_file;

    {
        local $@;
        eval { $csv_file = $obj->write_adjacentified_to_csv(); };
        like($@, qr/write_adjacentified_to_csv\(\) must be supplied with hashref/,
            "write_adjacentified_to_csv() failed due to lack of argument");
    }

    {
        local $@;
        eval {
            $csv_file = $obj->write_adjacentified_to_csv(
                adjacentified => $adjacentified,
            );
        };
        like($@, qr/Argument to 'adjacentify\(\)' must be hashref/,
            "write_adjacentified_to_csv() failed due to non-hashref argument");
    }

    {
        local $@;
        eval {
            $csv_file = $obj->write_adjacentified_to_csv( [
                adjacentified => $adjacentified,
            ] );
        };
        like($@, qr/Argument to 'adjacentify\(\)' must be hashref/,
            "write_adjacentified_to_csv() failed due to non-hashref argument");
    }

    {
        local $@;
        eval {
            $csv_file = $obj->write_adjacentified_to_csv( {
                adjacentified => 'not an array reference',
            } );
        };
        like($@, qr/Argument 'adjacentified' must be array reference/,
            "write_adjacentified_to_csv() failed due to non-reference value for 'adjacentified'");
    }

    {
        local $@;
        eval {
            $csv_file = $obj->write_adjacentified_to_csv( {
                adjacentified => {},
            } );
        };
        like($@, qr/Argument 'adjacentified' must be array reference/,
            "write_adjacentified_to_csv() failed due to non-arrayref value for 'adjacentified'");
    }

    {
        local $@;
        eval {
            $csv_file = $obj->write_adjacentified_to_csv( { sep_char => '|' } );
        };
        like($@, qr/Argument to 'adjacentify\(\)' must have 'adjacentified' element/,
            "write_adjacentified_to_csv() failed due to lack of 'adjacentified' element");
    }

    $csv_file = $obj->write_adjacentified_to_csv( {
       adjacentified => $adjacentified,
       csvfile => './t/data/taxonomy_out.csv',
    } );
    ok($csv_file, "write_adjacentified_to_csv() returned '$csv_file'");
    ok((-f $csv_file), "'$csv_file' is plain-text file");
    ok((-r $csv_file), "'$csv_file' is readable");
}

{
    $source = "./t/data/beta.csv";
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    note("adjacentify()");
    my $serial = 500;
    $adjacentified = $obj->adjacentify( { serial => $serial } );
    ok($adjacentified, "'adjacentify() returned true value");
    my @ids_seen = map { $_->{id} } @{$adjacentified};
    my $expect = 501;
    is(min(@ids_seen), $expect,
        "Lowest 'id' value is $expect, as serial was set to $serial");

    note("write_adjacentified_to_csv()");
    my $csv_file;
    $csv_file = $obj->write_adjacentified_to_csv( {
       adjacentified => $adjacentified,
       csvfile => './t/data/taxonomy_out1.csv',
       sep_char => '|',
    } );

    {
        my $cwd = cwd();
        my $tdir = tempdir(CLEANUP => 1);
        chdir $tdir or croak "Unable to change to $tdir";
        $csv_file = $obj->write_adjacentified_to_csv( {
            adjacentified => $adjacentified,
        } );
        ok(-f "$tdir/taxonomy_out.csv", "Wrote CSV file in current directory");
        chdir $cwd or croak "Unable to change back to $cwd";
    }

}

{
    note("Non-siblings can have same name");
    $source = "./t/data/non_sibling_same_name.csv";
    note($source);
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file                => $source,
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    note("adjacentify()");
    my $serial = 420;
    $adjacentified = $obj->adjacentify( { serial => $serial } );
    ok($adjacentified, "'adjacentify() returned true value");
    my @ids_seen = map { $_->{id} } @{$adjacentified};
    my $expect = 421;
    is(min(@ids_seen), $expect,
        "Lowest 'id' value is $expect, as serial was set to $serial");

    note("write_adjacentified_to_csv()");
    my $csv_file;
    $csv_file = $obj->write_adjacentified_to_csv( {
       adjacentified => $adjacentified,
       csvfile => './t/data/taxonomy_out2.csv',
       sep_char => '|',
    } );

}

{
    my $csv_file;

    # A small taxonomy-by-materialized-path
    $source = "./t/data/iota.csv";
    note($source);
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file => $source,
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    note("adjacentify()");
    $adjacentified = $obj->adjacentify();
    ok($adjacentified, "'adjacentify() returned true value");

    note("write_adjacentified_to_csv()");
    $csv_file = $obj->write_adjacentified_to_csv( {
       adjacentified => $adjacentified,
       csvfile => './t/data/taxonomy_out3.csv',
    } );

    # Another small taxonomy-by-materialized-path
    $source = "./t/data/kappa.csv";
    note($source);
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file => $source,
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

    note("adjacentify()");
    $adjacentified = $obj->adjacentify();
    ok($adjacentified, "'adjacentify() returned true value");

    note("write_adjacentified_to_csv()");
    $csv_file = $obj->write_adjacentified_to_csv( {
       adjacentified => $adjacentified,
       csvfile => './t/data/taxonomy_out4.csv',
    } );

}
