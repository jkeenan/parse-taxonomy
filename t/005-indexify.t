# perl
# t/005-indexify.t
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::Taxonomy::Path;
use Test::More qw(no_plan); # tests => 15;
use List::Util qw( min );
use Cwd;
use File::Temp qw/ tempdir /;

my ($obj, $source, $expect, $indexified);

{
    $source = "./t/data/beta.csv";
    $obj = Parse::Taxonomy::Path->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::Path');

    local $@;
    eval {
        $indexified = $obj->indexify(
            serial => 500,
        );
    };
    like($@, qr/^Argument to 'indexify\(\)' must be hashref/,
        "'indexify()' died to lack of hashref as argument; was just a key-value pair");

    local $@;
    eval {
        $indexified = $obj->indexify( [
            serial => 500,
        ] );
    };
    like($@, qr/^Argument to 'indexify\(\)' must be hashref/,
        "'indexify()' died to lack of hashref as argument; was arrayref");
}

{
    $source = "./t/data/beta.csv";
    $obj = Parse::Taxonomy::Path->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::Path');

    note("indexify()");
    $indexified = $obj->indexify();
    ok($indexified, "'indexify() returned true value");
    my @ids_seen = map { $_->{id} } @{$indexified};
    is(min(@ids_seen), 1,
        "Lowest 'id' value is 1, as serial defaults to 0");

    note("write_indexified_to_csv()");
    my $csv_file;

    {
        local $@;
        eval { $csv_file = $obj->write_indexified_to_csv(); };
        like($@, qr/write_indexified_to_csv\(\) must be supplied with hashref/,
            "write_indexified_to_csv() failed due to lack of argument");
    }

    {
        local $@;
        eval {
            $csv_file = $obj->write_indexified_to_csv(
                indexified => $indexified,
            );
        };
        like($@, qr/Argument to 'indexify\(\)' must be hashref/,
            "write_indexified_to_csv() failed due to non-hashref argument");
    }

    {
        local $@;
        eval {
            $csv_file = $obj->write_indexified_to_csv( [
                indexified => $indexified,
            ] );
        };
        like($@, qr/Argument to 'indexify\(\)' must be hashref/,
            "write_indexified_to_csv() failed due to non-hashref argument");
    }

    {
        local $@;
        eval {
            $csv_file = $obj->write_indexified_to_csv( {
                indexified => 'not an array reference',
            } );
        };
        like($@, qr/Argument 'indexified' must be array reference/,
            "write_indexified_to_csv() failed due to non-reference value for 'indexified'");
    }

    {
        local $@;
        eval {
            $csv_file = $obj->write_indexified_to_csv( {
                indexified => {},
            } );
        };
        like($@, qr/Argument 'indexified' must be array reference/,
            "write_indexified_to_csv() failed due to non-arrayref value for 'indexified'");
    }

    {
        local $@;
        eval {
            $csv_file = $obj->write_indexified_to_csv( { sep_char => '|' } );
        };
        like($@, qr/Argument to 'indexify\(\)' must have 'indexified' element/,
            "write_indexified_to_csv() failed due to lack of 'indexified' element");
    }

    $csv_file = $obj->write_indexified_to_csv( {
       indexified => $indexified,
       csvfile => './t/data/taxonomy_out.csv',
    } );
    ok($csv_file, "write_indexified_to_csv() returned '$csv_file'");
    ok((-f $csv_file), "'$csv_file' is plain-text file");
    ok((-r $csv_file), "'$csv_file' is readable");
}

{
    $source = "./t/data/beta.csv";
    $obj = Parse::Taxonomy::Path->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::Path');

    note("indexify()");
    my $serial = 500;
    $indexified = $obj->indexify( { serial => $serial } );
    ok($indexified, "'indexify() returned true value");
    my @ids_seen = map { $_->{id} } @{$indexified};
    my $expect = 501;
    is(min(@ids_seen), $expect,
        "Lowest 'id' value is $expect, as serial was set to $serial");

    note("write_indexified_to_csv()");
    my $csv_file;
    $csv_file = $obj->write_indexified_to_csv( {
       indexified => $indexified,
       csvfile => './t/data/taxonomy_out1.csv',
       sep_char => '|',
    } );

    {
        my $cwd = cwd();
        my $tdir = tempdir(CLEANUP => 1);
        chdir $tdir or croak "Unable to change to $tdir";
        $csv_file = $obj->write_indexified_to_csv( {
            indexified => $indexified,
        } );
        ok(-f "$tdir/taxonomy_out.csv", "Wrote CSV file in current directory");
        chdir $cwd or croak "Unable to change back to $cwd";
    }

}

{
    note("Non-siblings can have same name");
    $source = "./t/data/non_sibling_same_name.csv";
    note($source);
    $obj = Parse::Taxonomy::Path->new( {
        file                => $source,
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::Path');

    note("indexify()");
    my $serial = 420;
    $indexified = $obj->indexify( { serial => $serial } );
    ok($indexified, "'indexify() returned true value");
    my @ids_seen = map { $_->{id} } @{$indexified};
    my $expect = 421;
    is(min(@ids_seen), $expect,
        "Lowest 'id' value is $expect, as serial was set to $serial");

    note("write_indexified_to_csv()");
    my $csv_file;
    $csv_file = $obj->write_indexified_to_csv( {
       indexified => $indexified,
       csvfile => './t/data/taxonomy_out2.csv',
       sep_char => '|',
    } );

}

{
    # A small taxonomy-by-path
    $source = "./t/data/iota.csv";
    note($source);
    $obj = Parse::Taxonomy::Path->new( {
        file                => $source,
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::Path');

    note("indexify()");
    $indexified = $obj->indexify();
    ok($indexified, "'indexify() returned true value");

    note("write_indexified_to_csv()");
    my $csv_file;
    $csv_file = $obj->write_indexified_to_csv( {
       indexified => $indexified,
       csvfile => './t/data/taxonomy_out3.csv',
    } );
}
