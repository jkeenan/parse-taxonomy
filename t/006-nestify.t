# perl
# t/006-nestify.t
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::Taxonomy::MaterializedPath;
use Test::More qw(no_plan); # tests => 19;
use Data::Dump;

my ($obj, $source, $expect, $hashified);

{
    $source = "./t/data/nu.csv";
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');
    $expect = {
        "|Alpha" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "|Alpha|Epsilon" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Epsilon",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "|Alpha|Epsilon|Kappa" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Epsilon|Kappa",
                    retail_price => "0.60",
                    vertical => "Auto",
                    wholesale_price => "0.50",
                  },
        "|Alpha|Zeta" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "|Alpha|Zeta|Lambda" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Zeta|Lambda",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "|Alpha|Zeta|Mu" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta|Mu",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
    };
    $hashified = $obj->hashify();
    is_deeply($hashified, $expect, "Got expected hashified taxonomy (no args)");

    my $nest;
    ok($nest = $obj->nestify(), "nestify() returned true value");

    my $expect = {
      "|Alpha"               => {
                                  children => {
                                    "|Alpha|Epsilon" => { handled => 1 },
                                    "|Alpha|Zeta"    => { handled => 1 },
                                  },
                                  lft => 1,
                                  parent => "",
                                  rgh => 12,
                                  row_depth => 2,
                                },
      "|Alpha|Epsilon"       => {
                                  children => { "|Alpha|Epsilon|Kappa" => { handled => 1 } },
                                  lft => 2,
                                  parent => "|Alpha",
                                  rgh => 5,
                                  row_depth => 3,
                                },
      "|Alpha|Epsilon|Kappa" => { lft => 3, parent => "|Alpha|Epsilon", rgh => 4, row_depth => 4 },
      "|Alpha|Zeta"          => {
                                  children => {
                                    "|Alpha|Zeta|Lambda" => { handled => 1 },
                                    "|Alpha|Zeta|Mu"     => { handled => 1 },
                                  },
                                  lft => 6,
                                  parent => "|Alpha",
                                  rgh => 11,
                                  row_depth => 3,
                                },
      "|Alpha|Zeta|Lambda"   => { lft => 7, parent => "|Alpha|Zeta", rgh => 8, row_depth => 4 },
      "|Alpha|Zeta|Mu"       => { lft => 9, parent => "|Alpha|Zeta", rgh => 10, row_depth => 4 },
    };
    is_deeply($nest, $expect, "Got expected nested set");
}


