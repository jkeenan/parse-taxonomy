# perl
use strict;
use warnings;
use 5.10.1;
use Data::Dumper;$Data::Dumper::Indent=1;
use Data::Dump;
use Carp;
use lib qw( lib );
use Parse::Taxonomy::Path;
use Parse::Taxonomy::Index;
use Scalar::Util qw( reftype );
use Test::More qw( no_plan );

my $dir = '/home/jkeenan/gitwork/parse-taxonomy';
my $taxfile = "$dir/t/data/iota.csv";
my $csvfile = "/home/jkeenan/learn/perl/pft/greeks.csv";

my ($source, $obj, $pathified);
$source = $csvfile;
note($source);
$obj = Parse::Taxonomy::Index->new( {
    file    => $source,
} );
ok(defined $obj, "new() returned defined value");
isa_ok($obj, 'Parse::Taxonomy::Index');

$pathified = $obj->pathify;
ok($pathified, "pathify() returned true value");
ok(ref($pathified), "pathify() returned reference");
is(reftype($pathified), 'ARRAY', "pathify() returned array reference");
Data::Dump::pp($pathified);
