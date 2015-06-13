# perl
# t/004-local-validate.t
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::File::Taxonomy::Path;
use Test::More qw(no_plan); # tests => 6;
#use Data::Dump;

my ($obj, $source, $rv, $lv, $expect);

$source = "./t/data/beta.csv";
$obj = Parse::File::Taxonomy::Path->new( {
    file    => $source,
} );
ok(defined $obj, "'new()' returned defined value");
isa_ok($obj, 'Parse::File::Taxonomy::Path');

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
        $obj->local_validate( [
            { description => 'hello', rule => sub { "Hello world" } },
            [ 'foo', 'bar' ],
        ] );
    };
    like($@, qr/Each element in arrayref of arguments to local_validate\(\) must be a hash ref/,
        "local_validate() failed due to non-hashref in array");
}

{
    local $@;
    eval {
        $obj->local_validate( [
            { description => 'hello', rule => sub { "Hello world" } },
            'scalar',
        ] );
    };
    like($@, qr/Each element in arrayref of arguments to local_validate\(\) must be a hash ref/,
        "local_validate() failed due to non-hashref in array");
}

{
    local $@;
    my $missing = 'rule';
    eval {
        $obj->local_validate( [
            { description => 'hello', mule => sub { "Hello world" } },
        ] );
    };
    like($@, qr/Each hashref in arguments to local_validate\(\) must have a '$missing' key-value pair/,
        "local_validate() failed due to lack of '$missing' key-value pair");
}

{
    local $@;
    my $missing = 'description';
    eval {
        $obj->local_validate( [
            { conniption => 'hello', rule => sub { "Hello world" } },
        ] );
    };
    like($@, qr/Each hashref in arguments to local_validate\(\) must have a '$missing' key-value pair/,
        "local_validate() failed due to lack of '$missing' key-value pair");
    ok(! defined($obj->get_local_validations), "Local validations not set");
}

{
    $rv = $obj->local_validate( [
        { description => 'hello',   rule => sub { "Hello world" } },
        { description => 'goodbye', rule => sub { "Goodbye world" } },
    ] );
    ok($rv, "local_validate() returned true value");
    $lv = $obj->get_local_validations;
    $expect = [
        { boolean => 1, description => "hello", return => "Hello world" },
        { boolean => 1, description => "goodbye", return => "Goodbye world" },
    ];
    is_deeply($lv, $expect, "Got expected list of local validation results");

}

{
    $rv = $obj->local_validate( [
        { description => 'hello',   rule => sub { "Hello world" } },
        { description => 'goodbye', rule => sub { return 0 } },
    ] );
    ok(!$rv, "local_validate() returned false value");
    $lv = $obj->get_local_validations;
    $expect = [
        { boolean => 1, description => "hello", return => "Hello world" },
        { boolean => "", description => "goodbye", return => 0 },
    ];
    is_deeply($lv, $expect, "Got expected list of local validation results");
}

{
    $rv = $obj->local_validate( [
        { description => 'hello',   rule => sub { "Hello world" } },
        { description => 'goodbye', rule => sub { return '' } },
    ] );
    ok(!$rv, "local_validate() returned false value");
    $lv = $obj->get_local_validations;
    $expect = [
        { boolean => 1, description => "hello", return => "Hello world" },
        { boolean => "", description => "goodbye", return => '' },
    ];
    is_deeply($lv, $expect, "Got expected list of local validation results");
}

{
    my $data_records = $obj->data_records;
    my $fdr = $obj->fields_and_data_records;
    my $is_actionable_idx = $obj->get_field_position('is_actionable');
    my $check_actionable = sub {
        my $obj = shift;
        my $data_records = $obj->data_records;
        my $mismatched = 0;
        for my $rec (@{$data_records}) {
            my $thispath = $rec->[$obj->path_col_idx];
            my $is_actionable = $rec->[$is_actionable_idx];
            my $child_count = $obj->get_child_count($thispath);
            if ($child_count && $is_actionable) {
                $mismatched++;
            }
        }
        $mismatched ? 0 : 1;
    };
    $rv = $obj->local_validate( [
        { description => 'actionable',   rule => $check_actionable },
    ] );
    ok($rv, "local_validate() returned true value");
    $lv = $obj->get_local_validations;
    $expect = [
        { boolean => 1, description => "actionable", return => 1 },
    ];
    is_deeply($lv, $expect, "Got expected list of local validation results");

}


