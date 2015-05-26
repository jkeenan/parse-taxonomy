# perl
# t/002-hashify-taxonomy.t
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
    $source = "./t/data/beta.csv";
    $obj = Parse::File::Taxonomy->new( {
        file    => $source,
    } );
    ok(defined $obj, "'new()' returned defined value");
    isa_ok($obj, 'Parse::File::Taxonomy');

    my $hashified;
    $hashified = $obj->hashify_taxonomy();
    $expect = {
        "Alpha" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "Alpha|Epsilon" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Epsilon",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "Alpha|Epsilon|Kappa" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Epsilon|Kappa",
                    retail_price => "0.60",
                    vertical => "Auto",
                    wholesale_price => "0.50",
                  },
        "Alpha|Zeta" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "Alpha|Zeta|Lambda" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Zeta|Lambda",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "Alpha|Zeta|Mu" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta|Mu",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "Beta" => {
                    currency_code => "JPY",
                    is_actionable => 0,
                    path => "|Beta",
                    retail_price => "",
                    vertical => "Electronics",
                    wholesale_price => "",
                  },
        "Beta|Eta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Eta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "Beta|Theta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Theta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "Gamma" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "Gamma|Iota" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma|Iota",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "Gamma|Iota|Nu" => {
                    currency_code => "EUR",
                    is_actionable => 1,
                    path => "|Gamma|Iota|Nu",
                    retail_price => 0.75,
                    vertical => "Travel",
                    wholesale_price => "0.60",
                  },
        "Delta" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Delta",
                    retail_price => "0.30",
                    vertical => "Life Insurance",
                    wholesale_price => 0.25,
                  },
    };
    is_deeply($hashified, $expect, "Got it");

    $hashified = $obj->hashify_taxonomy( {
        key_delim => q{ - },
    } );
#say STDERR "AAA:";
#Data::Dump::pp($hashified);
#say STDERR "BBB:";

    $expect = {
        "Alpha" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "Alpha - Epsilon" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Epsilon",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "Alpha - Epsilon - Kappa" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Epsilon|Kappa",
                    retail_price => "0.60",
                    vertical => "Auto",
                    wholesale_price => "0.50",
                  },
        "Alpha - Zeta" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta",
                    retail_price => "",
                    vertical => "Auto",
                    wholesale_price => "",
                  },
        "Alpha - Zeta - Lambda" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Alpha|Zeta|Lambda",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "Alpha - Zeta - Mu" => {
                    currency_code => "USD",
                    is_actionable => 0,
                    path => "|Alpha|Zeta|Mu",
                    retail_price => "0.50",
                    vertical => "Auto",
                    wholesale_price => "0.40",
                  },
        "Beta" => {
                    currency_code => "JPY",
                    is_actionable => 0,
                    path => "|Beta",
                    retail_price => "",
                    vertical => "Electronics",
                    wholesale_price => "",
                  },
        "Beta - Eta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Eta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "Beta - Theta" => {
                    currency_code => "JPY",
                    is_actionable => 1,
                    path => "|Beta|Theta",
                    retail_price => 0.45,
                    vertical => "Electronics",
                    wholesale_price => 0.35,
                  },
        "Gamma" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "Gamma - Iota" => {
                    currency_code => "EUR",
                    is_actionable => 0,
                    path => "|Gamma|Iota",
                    retail_price => "",
                    vertical => "Travel",
                    wholesale_price => "",
                  },
        "Gamma - Iota - Nu" => {
                    currency_code => "EUR",
                    is_actionable => 1,
                    path => "|Gamma|Iota|Nu",
                    retail_price => 0.75,
                    vertical => "Travel",
                    wholesale_price => "0.60",
                  },
        "Delta" => {
                    currency_code => "USD",
                    is_actionable => 1,
                    path => "|Delta",
                    retail_price => "0.30",
                    vertical => "Life Insurance",
                    wholesale_price => 0.25,
                  },
    };
    is_deeply($hashified, $expect, "Got it");

}

