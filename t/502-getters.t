# perl
# t/502-getters.t - Tests of methods which get data out of object
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
    $source = "./t/data/delta.csv";
    note($source);
    $obj = Parse::File::Taxonomy::Index->new( {
        file    => $source,
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::File::Taxonomy::Index');

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

    $expect = ["my_id","my_parent_id","my_name","vertical","currency_code","wholesale_price","retail_price","is_actionable"];
    is_deeply($obj->fields, $expect, "Got expected columns");
}

