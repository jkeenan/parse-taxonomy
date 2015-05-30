# perl
# t/004-local-validate.t
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::File::Taxonomy;
use Test::More tests => 6;
use Data::Dump;

my ($obj, $source);

$source = "./t/data/beta.csv";
$obj = Parse::File::Taxonomy->new( {
    file    => $source,
} );
ok(defined $obj, "'new()' returned defined value");
isa_ok($obj, 'Parse::File::Taxonomy');

{
    local $@;
    eval { $obj->local_validate(); };
    like($@, qr/Argument to local_validate\(\) must be an array ref/,
        "local_validate() failed due to lack of array ref");
}

{
    local $@;
    eval { $obj->local_validate({}); };
    like($@, qr/Argument to local_validate\(\) must be an array ref/,
        "local_validate() failed due to lack of array ref");
}

{
    local $@;
    eval {
        $obj->local_validate( [ sub { "Hello world" }, 'foo' ] );
    };
    like($@, qr/Each element in arrayref of arguments to local_validate\(\) must be a code ref/,
        "local_validate() failed due to non-coderef in array");
}

ok($obj->local_validate( [ sub { "Hello world" }, sub { "Goodbye world" } ] ),
    "local_validate() returned true value");


