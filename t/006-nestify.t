# perl
# t/006-nestify.t
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::Taxonomy::MaterializedPath;
use Test::More tests => 13;

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
    {
        local $@;
        eval { $nest = $obj->nestify( floor => 500 ); };
        like($@,
            qr/Argument to 'nestify\(\)' must be hashref/,
            "Got expected error: nestify() must take hashref"
        );
    }

    {
        local $@;
        eval { $nest = $obj->nestify( [ floor => 500 ] ); };
        like($@,
            qr/Argument to 'nestify\(\)' must be hashref/,
            "Got expected error: nestify() must take hashref"
        );
    }

    my $diag;
    ok($diag = $obj->nestify( { diagnostic => 1 } ), "nestify() returned true value");

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
    is_deeply($diag, $expect, "Got expected diagnostic nest");
}

{
    $source = "./t/data/beta.csv";
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');

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
      "|Beta"                => {
                                  children => { "|Beta|Eta" => { handled => 1 }, "|Beta|Theta" => { handled => 1 } },
                                  lft => 13,
                                  parent => "",
                                  rgh => 18,
                                  row_depth => 2,
                                },
      "|Beta|Eta"            => { lft => 14, parent => "|Beta", rgh => 15, row_depth => 3 },
      "|Beta|Theta"          => { lft => 16, parent => "|Beta", rgh => 17, row_depth => 3 },
      "|Delta"               => { lft => 19, parent => "", rgh => 20, row_depth => 2 },
      "|Gamma"               => {
                                  children => { "|Gamma|Iota" => { handled => 1 } },
                                  lft => 21,
                                  parent => "",
                                  rgh => 26,
                                  row_depth => 2,
                                },
      "|Gamma|Iota"          => {
                                  children => { "|Gamma|Iota|Nu" => { handled => 1 } },
                                  lft => 22,
                                  parent => "|Gamma",
                                  rgh => 25,
                                  row_depth => 3,
                                },
      "|Gamma|Iota|Nu"       => { lft => 23, parent => "|Gamma|Iota", rgh => 24, row_depth => 4 },
    };

    my $diag;
    ok($diag = $obj->nestify( { diagnostic => 1 } ), "nestify() returned true value");
    is_deeply($diag, $expect, "Got expected diagnostic nest");

    $expect = {
      "|Alpha"               => {
                                  currency_code => "USD",
                                  is_actionable => 0,
                                  lft => 1,
                                  name => "Alpha",
                                  retail_price => "",
                                  rgh => 12,
                                  vertical => "Auto",
                                  wholesale_price => "",
                                },
      "|Alpha|Epsilon"       => {
                                  currency_code => "USD",
                                  is_actionable => 0,
                                  lft => 2,
                                  name => "Epsilon",
                                  retail_price => "",
                                  rgh => 5,
                                  vertical => "Auto",
                                  wholesale_price => "",
                                },
      "|Alpha|Epsilon|Kappa" => {
                                  currency_code => "USD",
                                  is_actionable => 1,
                                  lft => 3,
                                  name => "Kappa",
                                  retail_price => "0.60",
                                  rgh => 4,
                                  vertical => "Auto",
                                  wholesale_price => "0.50",
                                },
      "|Alpha|Zeta"          => {
                                  currency_code => "USD",
                                  is_actionable => 0,
                                  lft => 6,
                                  name => "Zeta",
                                  retail_price => "",
                                  rgh => 11,
                                  vertical => "Auto",
                                  wholesale_price => "",
                                },
      "|Alpha|Zeta|Lambda"   => {
                                  currency_code => "USD",
                                  is_actionable => 1,
                                  lft => 7,
                                  name => "Lambda",
                                  retail_price => "0.50",
                                  rgh => 8,
                                  vertical => "Auto",
                                  wholesale_price => "0.40",
                                },
      "|Alpha|Zeta|Mu"       => {
                                  currency_code => "USD",
                                  is_actionable => 0,
                                  lft => 9,
                                  name => "Mu",
                                  retail_price => "0.50",
                                  rgh => 10,
                                  vertical => "Auto",
                                  wholesale_price => "0.40",
                                },
      "|Beta"                => {
                                  currency_code => "JPY",
                                  is_actionable => 0,
                                  lft => 13,
                                  name => "Beta",
                                  retail_price => "",
                                  rgh => 18,
                                  vertical => "Electronics",
                                  wholesale_price => "",
                                },
      "|Beta|Eta"            => {
                                  currency_code => "JPY",
                                  is_actionable => 1,
                                  lft => 14,
                                  name => "Eta",
                                  retail_price => 0.45,
                                  rgh => 15,
                                  vertical => "Electronics",
                                  wholesale_price => 0.35,
                                },
      "|Beta|Theta"          => {
                                  currency_code => "JPY",
                                  is_actionable => 1,
                                  lft => 16,
                                  name => "Theta",
                                  retail_price => 0.45,
                                  rgh => 17,
                                  vertical => "Electronics",
                                  wholesale_price => 0.35,
                                },
      "|Delta"               => {
                                  currency_code => "USD",
                                  is_actionable => 1,
                                  lft => 19,
                                  name => "Delta",
                                  retail_price => "0.30",
                                  rgh => 20,
                                  vertical => "Life Insurance",
                                  wholesale_price => 0.25,
                                },
      "|Gamma"               => {
                                  currency_code => "EUR",
                                  is_actionable => 0,
                                  lft => 21,
                                  name => "Gamma",
                                  retail_price => "",
                                  rgh => 26,
                                  vertical => "Travel",
                                  wholesale_price => "",
                                },
      "|Gamma|Iota"          => {
                                  currency_code => "EUR",
                                  is_actionable => 0,
                                  lft => 22,
                                  name => "Iota",
                                  retail_price => "",
                                  rgh => 25,
                                  vertical => "Travel",
                                  wholesale_price => "",
                                },
      "|Gamma|Iota|Nu"       => {
                                  currency_code => "EUR",
                                  is_actionable => 1,
                                  lft => 23,
                                  name => "Nu",
                                  retail_price => 0.75,
                                  rgh => 24,
                                  vertical => "Travel",
                                  wholesale_price => "0.60",
                                },
    };
    my $nest;
    ok($nest = $obj->nestify( ), "nestify() returned true value");
    is_deeply($nest, $expect, "Got expected diagnostic nest");
}
