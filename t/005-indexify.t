# perl
# t/005-indexify.t
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::File::Taxonomy::Path;
use Test::More qw(no_plan); # tests => 15;
#use Data::Dump;

my ($obj, $source, $expect, $indexified);

{
    $source = "./t/data/beta.csv";
    $obj = Parse::File::Taxonomy::Path->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::File::Taxonomy::Path');

    local $@;
    # TODO: Change key_delim to something meaningful
    eval {
        $indexified = $obj->indexify(
            key_delim => q{ - },
        );
    };
    like($@, qr/^Argument to 'indexify\(\)' must be hashref/,
        "'indexify()' died to lack of hashref as argument; was just a key-value pair");

    local $@;
    # TODO: Change key_delim to something meaningful
    eval {
        $indexified = $obj->indexify( [
            key_delim => q{ - },
        ] );
    };
    like($@, qr/^Argument to 'indexify\(\)' must be hashref/,
        "'indexify()' died to lack of hashref as argument; was arrayref");
}

{
    $source = "./t/data/beta.csv";
    $obj = Parse::File::Taxonomy::Path->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::File::Taxonomy::Path');

    $indexified = $obj->indexify();
    ok($indexified, "'indexify() returned true value");

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

    $csv_file = $obj->write_indexified_to_csv( {
       indexified => $indexified,
       csvfile => './t/data/taxonomy_out.csv',
    } );
    ok($csv_file, "write_indexified_to_csv() returned '$csv_file'");
    ok((-f $csv_file), "'$csv_file' is plain-text file");
    ok((-r $csv_file), "'$csv_file' is readable");
}

