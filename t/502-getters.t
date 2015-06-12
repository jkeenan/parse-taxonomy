# perl
# t/502-getters.t - Tests of methods which get data out of object
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::File::Taxonomy::Index;
use Test::More tests => 12;
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

{
    note("'components' interface");
    $obj = Parse::File::Taxonomy::Index->new( {
        components => {
            fields =>
                ["id","parent_id","name","vertical","currency_code","wholesale_price","retail_price","is_actionable"],
            data_records    => [
              ["1","","Alpha","Auto","USD","","","0"],
              ["3","1","Epsilon","Auto","USD","","","0"],
              ["4","3","Kappa","Auto","USD","0.50","0.60","1"],
              ["5","1","Zeta","Auto","USD","","","0"],
              ["6","5","Lambda","Auto","USD","0.40","0.50","1"],
              ["7","5","Mu","Auto","USD","0.40","0.50","0"],
              ["2","","Beta","Electronics","JPY","","","0"],
              ["8","2","Eta","Electronics","JPY","0.35","0.45","1"],
              ["9","2","Theta","Electronics","JPY","0.35","0.45","1"],
              ["10","","Gamma","Travel","EUR","","","0"],
              ["11","10","Iota","Travel","EUR","","","0"],
              ["12","11","Nu","Travel","EUR","0.60","0.75","1"],
              ["13","","Delta","Life Insurance","USD","0.25","0.30","1"],
            ],
        },
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::File::Taxonomy::Index');

    $expect = ["id","parent_id","name","vertical","currency_code","wholesale_price","retail_price","is_actionable"];
    is_deeply($obj->fields, $expect, "Got expected columns");
}

{
#    $source = "./t/data/zeta.csv";
    note("'components' interface; user-supplied column names");
    $obj = Parse::File::Taxonomy::Index->new( {
#        file                => $source,
        components => {
            fields => ["my_id","my_parent_id","my_name","vertical","currency_code","wholesale_price","retail_price","is_actionable"],

            data_records    => [
              ["1","","Alpha","Auto","USD","","","0"],
              ["3","1","Epsilon","Auto","USD","","","0"],
              ["4","3","Kappa","Auto","USD","0.50","0.60","1"],
              ["5","1","Zeta","Auto","USD","","","0"],
              ["6","5","Lambda","Auto","USD","0.40","0.50","1"],
              ["7","5","Mu","Auto","USD","0.40","0.50","0"],
              ["2","","Beta","Electronics","JPY","","","0"],
              ["8","2","Eta","Electronics","JPY","0.35","0.45","1"],
              ["9","2","Theta","Electronics","JPY","0.35","0.45","1"],
              ["10","","Gamma","Travel","EUR","","","0"],
              ["11","10","Iota","Travel","EUR","","","0"],
              ["12","11","Nu","Travel","EUR","0.60","0.75","1"],
              ["13","","Delta","Life Insurance","USD","0.25","0.30","1"],
            ],
        },
        id_col              => 'my_id',
        parent_id_col       => 'my_parent_id',
        component_col       => 'my_name',
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::File::Taxonomy::Index');

    $expect = ["my_id","my_parent_id","my_name","vertical","currency_code","wholesale_price","retail_price","is_actionable"];
    is_deeply($obj->fields, $expect, "Got expected columns");
}

