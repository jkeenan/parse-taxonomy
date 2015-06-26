# perl
use strict;
use warnings;
use 5.10.1;
use Carp;
use lib qw( lib );
use Parse::Taxonomy::Path;
use Parse::Taxonomy::Index;
use Scalar::Util qw( reftype );
use Test::More qw( no_plan );

my $csvfile = "/home/jkeenan/learn/perl/pft/greeks.csv";

my $source = $csvfile;
note($source);
my $ptiobj = Parse::Taxonomy::Index->new( {
    file    => $source,
} );
ok(defined $ptiobj, "new() returned defined value");
isa_ok($ptiobj, 'Parse::Taxonomy::Index');

my $pathified = $ptiobj->pathify;
ok($pathified, "pathify() returned true value");
ok(ref($pathified), "pathify() returned reference");
is(reftype($pathified), 'ARRAY', "pathify() returned array reference");

my $fields = $pathified->[0];
my @data_records = ();
for my $rec (@{$pathified}[1..$#{$pathified}]) {
    my $bool = ($rec->[1] eq 't') ? 1 : 0;
    push @data_records, [
        join('|' => @{$rec->[0]}),
        ($rec->[1] eq 't') ? 1 : 0,
    ];
}

my $ptpobj = Parse::Taxonomy::Path->new( {
    components  => {
        fields          => $fields,
        data_records    => \@data_records,
    },
} );
my $fdr1 = $ptpobj->fields_and_data_records_path_components;

my $dir = '/home/jkeenan/gitwork/parse-taxonomy';
my $taxfile = "$dir/t/data/mu.csv";

my $tax = Parse::Taxonomy::Path->new( {
    file => $taxfile,
    path_col_sep => '--',
} );
my $fdr2 = $tax->fields_and_data_records_path_components;
is_deeply($fdr1, $fdr2, "QED");
