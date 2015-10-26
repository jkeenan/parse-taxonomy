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

#{
#    $source = "./t/data/nu.csv";
#    $obj = Parse::Taxonomy::MaterializedPath->new( {
#        file    => $source,
#    } );
#    ok(defined $obj, "'new()' returned defined value");
#    isa_ok($obj, 'Parse::Taxonomy::MaterializedPath');
#    $expect = {
#        "|Alpha" => {
#                    currency_code => "USD",
#                    is_actionable => 0,
#                    path => "|Alpha",
#                    retail_price => "",
#                    vertical => "Auto",
#                    wholesale_price => "",
#                  },
#        "|Alpha|Epsilon" => {
#                    currency_code => "USD",
#                    is_actionable => 0,
#                    path => "|Alpha|Epsilon",
#                    retail_price => "",
#                    vertical => "Auto",
#                    wholesale_price => "",
#                  },
#        "|Alpha|Epsilon|Kappa" => {
#                    currency_code => "USD",
#                    is_actionable => 1,
#                    path => "|Alpha|Epsilon|Kappa",
#                    retail_price => "0.60",
#                    vertical => "Auto",
#                    wholesale_price => "0.50",
#                  },
#        "|Alpha|Zeta" => {
#                    currency_code => "USD",
#                    is_actionable => 0,
#                    path => "|Alpha|Zeta",
#                    retail_price => "",
#                    vertical => "Auto",
#                    wholesale_price => "",
#                  },
#        "|Alpha|Zeta|Lambda" => {
#                    currency_code => "USD",
#                    is_actionable => 1,
#                    path => "|Alpha|Zeta|Lambda",
#                    retail_price => "0.50",
#                    vertical => "Auto",
#                    wholesale_price => "0.40",
#                  },
#        "|Alpha|Zeta|Mu" => {
#                    currency_code => "USD",
#                    is_actionable => 0,
#                    path => "|Alpha|Zeta|Mu",
#                    retail_price => "0.50",
#                    vertical => "Auto",
#                    wholesale_price => "0.40",
#                  },
#    };
#    $hashified = $obj->hashify();
#    is_deeply($hashified, $expect, "Got expected hashified taxonomy (no args)");
#
#    my $nest;
#    {
#        local $@;
#        eval { $nest = $obj->nestify( floor => 500 ); };
#        like($@,
#            qr/Argument to 'nestify\(\)' must be hashref/,
#            "Got expected error: nestify() must take hashref"
#        );
#    }
#
#    {
#        local $@;
#        eval { $nest = $obj->nestify( [ floor => 500 ] ); };
#        like($@,
#            qr/Argument to 'nestify\(\)' must be hashref/,
#            "Got expected error: nestify() must take hashref"
#        );
#    }
#
#    my $diag;
#    ok($diag = $obj->nestify( { diagnostic => 1 } ), "nestify() returned true value");
#
#    my $expect = {
#      "|Alpha"               => {
#                                  children => {
#                                    "|Alpha|Epsilon" => { handled => 1 },
#                                    "|Alpha|Zeta"    => { handled => 1 },
#                                  },
#                                  lft => 1,
#                                  parent => "",
#                                  rgh => 12,
#                                  row_depth => 2,
#                                },
#      "|Alpha|Epsilon"       => {
#                                  children => { "|Alpha|Epsilon|Kappa" => { handled => 1 } },
#                                  lft => 2,
#                                  parent => "|Alpha",
#                                  rgh => 5,
#                                  row_depth => 3,
#                                },
#      "|Alpha|Epsilon|Kappa" => { lft => 3, parent => "|Alpha|Epsilon", rgh => 4, row_depth => 4 },
#      "|Alpha|Zeta"          => {
#                                  children => {
#                                    "|Alpha|Zeta|Lambda" => { handled => 1 },
#                                    "|Alpha|Zeta|Mu"     => { handled => 1 },
#                                  },
#                                  lft => 6,
#                                  parent => "|Alpha",
#                                  rgh => 11,
#                                  row_depth => 3,
#                                },
#      "|Alpha|Zeta|Lambda"   => { lft => 7, parent => "|Alpha|Zeta", rgh => 8, row_depth => 4 },
#      "|Alpha|Zeta|Mu"       => { lft => 9, parent => "|Alpha|Zeta", rgh => 10, row_depth => 4 },
#    };
#    is_deeply($diag, $expect, "Got expected diagnostic nest");
#}

{
    $source = "./t/data/beta.csv";
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
say STDERR "TTT:";
Data::Dump::pp($obj->{row_analysis});
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
say STDERR "UUU: diag";
Data::Dump::pp($diag);
### BUG: When I call nestify a *second* time on the same object, the lft and
#rgh get screwed up.  This appears to occur whether or not the second time
#around I call { diagnostic => 1 }.
say STDERR "VVV: nest only";
Data::Dump::pp($obj->nestify( { diagnostic => 1 } ));

### But when I create a completely new object, I get the desired results.
    $source = "./t/data/beta.csv";
    $obj = Parse::Taxonomy::MaterializedPath->new( {
        file    => $source,
    } );
say STDERR "WWW: nest only";
Data::Dump::pp($obj->nestify( ));
say STDERR "XXX: nest only";
Data::Dump::pp($obj->nestify( ));
#    my $nest;
#    ok($nest = $obj->nestify(), "nestify() returned true value");
#Data::Dump::pp($nest);

#    my @non_path_cols = grep { $_ ne $obj->{path_col} } @{$obj->fields};
#    my $hashified = $obj->hashify();
#    my %all_little = ();
#    for my $path (sort keys %{$hashified}) {
#        my %little = map { $_ => $hashified->{$path}->{$_} } @non_path_cols;
#        my @path_components = split(/\Q$obj->{path_col_sep}\E/, $hashified->{$path}->{$obj->{path_col}});
#        $little{name} = $path_components[-1];
#        $all_little{$path} = \%little;
#    }
#    my %nest_assembly = ();
#    for my $path (sort keys %{$diag}) {
#       my %this = (
#           lft => $diag->{$path}->{lft},
#           rgh => $diag->{$path}->{rgh},
#       );
#       for my $l (keys %{$all_little{$path}}) {
#           $this{$l} = $all_little{$path}{$l};
#       }
#       $nest_assembly{$path} = \%this;
#    }
#say STDERR "UUU:";
#Data::Dump::pp(\%nest_assembly);
#    my @nest = ();
#    for my $path (sort { $nest_assembly{$a}->{lft} <=> $nest_assembly{$b}->{lft} } keys %nest_assembly) {
#        push @nest, $nest_assembly{$path};
#    }
#say STDERR "WWW:";
#Data::Dump::pp(\@nest);

}
