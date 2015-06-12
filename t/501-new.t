# perl
# t/501-new.t - Tests of Parse::File::Taxonomy::Index constructor
use strict;
use warnings;
use Carp;
use utf8;

use lib ('./lib');
use Parse::File::Taxonomy::Index;
use Test::More qw(no_plan); # tests => 20;
use Data::Dump;

my ($obj, $source, $expect, $fields, $data_records);

{
    $source = "./t/data/epsilon.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new(
            file    => $source,
        );
    };
    like($@, qr/^Argument to 'new\(\)' must be hashref/,
        "new() died to lack of hashref as argument; was just a key-value pair");
}

{
    $source = "./t/data/epsilon.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( [
            file    => $source,
        ] );
    };
    like($@, qr/^Argument to 'new\(\)' must be hashref/,
        "new() died to lack of hashref as argument; was arrayref");
}

{
    $source = "./t/data/delta.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( { } );
    };
    like($@, qr/^Argument to 'new\(\)' must have either 'file' or 'components' element/,
        "'new()' died to lack of either 'file' or 'components' element in hashref passed as argument");
}

#{
#    $source = "./t/data/epsilon.csv";
#    local $@;
#    eval {
#        $obj = Parse::File::Taxonomy::Index->new( { } );
#    };
#    like($@, qr/^Argument to 'new\(\)' must have 'file' element/,
#        "new() died to lack of 'file' element in hashref passed as argument");
#}

{
    $source = "./t/data/nonexistent.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
        } );
    };
    like($@, qr/^Cannot locate file '$source'/,
        "new() died due to inability to find source file '$source'");
}

{
    $source = "./t/data/duplicate_header_field.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
        } );
    };
    like($@, qr/^Duplicate field.*?observed in '$source'/,
        "new() died due to duplicate column name in source file '$source'");
}

{
    $source = "./t/data/delta.csv";
    local $@;
    $expect = 'my_id';
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
            id_col  => $expect,
        } );
    };
    like($@, qr/Could not locate columns in header to match required arguments.*id_col.*$expect/s,
        "new() died: id_col '$expect' not found in header row");
}

{
    $source = "./t/data/delta.csv";
    local $@;
    $expect = 'my_parent_id';
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
            parent_id_col  => $expect,
        } );
    };
    like($@, qr/Could not locate columns in header to match required arguments.*parent_id_col.*$expect/s,
        "new() died: parent_id_col '$expect' not found in header row");
}

{
    $source = "./t/data/delta.csv";
    local $@;
    $expect = 'my_name';
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
            component_col  => $expect,
        } );
    };
    like($@, qr/Could not locate columns in header to match required arguments.*component_col.*$expect/s,
        "new() died: component_col '$expect' not found in header row");
}

{
    $source = "./t/data/duplicate_id.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
        } );
    };

    like($@, qr/^No duplicate entries are permitted in the 'id'column./s,
        "new() died due to duplicate values in column designated as 'id_col'");
    like($@, qr/2:\s+2/s, "More than one column had 'id' of 2");
    like($@, qr/3:\s+2/s, "More than one column had 'id' of 3");
}

{
    $source = "./t/data/bad_row_count.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
        } );
    };

    like($@, qr/^Header row has \d+ columns.  The following records/s,
        "new() died due to wrong number of columns in one or more rows");
    like($@, qr/1:\s+7/s, "Identified record with too few columns");
    like($@, qr/4:\s+5/s, "Identified record with too few columns");
    like($@, qr/13:\s+10/s, "Identified record with too many columns");
}

{
    $source = "t/data/ids_missing_parents.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
        } );
    };
    like($@, qr/^For each record with a non-null value in the 'parent_id' column/s,
        "new() died due to parent_id column values without corresponding id records");
}

{
    $source = "t/data/sibling_same_name.csv";
    local $@;
    eval {
        $obj = Parse::File::Taxonomy::Index->new( {
            file    => $source,
        } );
    };
    like($@, qr/^No record with a non-null value in the 'parent_id' column/s,
        "new() died due to parent with children sharing same name");
}

{
    $source = "./t/data/delta.csv";
    note($source);
    $obj = Parse::File::Taxonomy::Index->new( {
        file    => $source,
    } );
    ok(defined $obj, "new() returned defined value");
    isa_ok($obj, 'Parse::File::Taxonomy::Index');

    # Tests of default values: replace once we have accessors
    $expect = $source;
    is($obj->{file}, $expect, "file: $expect");

    $expect = 'id';
    is($obj->{id_col}, $expect, "id_col: $expect");

    $expect = 'parent_id';
    is($obj->{parent_id_col}, $expect, "parent_id_col: $expect");

    $expect = 'name';
    is($obj->{component_col}, $expect, "component_col: $expect");
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

    # Tests of default values: replace once we have accessors
    $expect = $source;
    is($obj->{file}, $expect, "file: $expect");

    $expect = 'my_id';
    is($obj->{id_col}, $expect, "id_col: $expect");

    $expect = 'my_parent_id';
    is($obj->{parent_id_col}, $expect, "parent_id_col: $expect");

    $expect = 'my_name';
    is($obj->{component_col}, $expect, "component_col: $expect");
}

{
    note("'components' interface to 'new()'");
    $fields = ["id","parent_id","name","vertical","currency_code","wholesale_price","retail_price","is_actionable"];
    $data_records = [
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
    ];

    {
        local $@;
        $source = "./t/data/delta.csv";
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                file        => $source,
                components  => {
                    fields          => $fields,
                    data_records    => $data_records,
                }
            } );
        };
        like($@,
            qr/Argument to 'new\(\)' must have either 'file' or 'components' element but not both/,
            "'new()' failed: cannot supply both 'file' and 'components' elements in arguments");
    }

    {
        local $@;
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => [
                    fields          => $fields,
                    data_records    => $data_records,
                ]
            } );
        };
        like($@,
            qr/Value of 'components' element must be hashref/,
            "'new()' failed: value of 'components' element must be hash ref");
    }

    {
        local $@;
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => 'foo',
            } );
        };
        like($@,
            qr/Value of 'components' element must be hashref/,
            "'new()' failed: value of 'components' element must be hash ref");
    }

    {
        local $@;
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => {
                    data_records    => $data_records,
                }
            } );
        };
        like($@, qr/Value of 'components' element must have 'fields' key-value pair/,
            "'new()' failed: 'components' element lacked 'fields' element");
    }

    {
        local $@;
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => {
                    fields    => $fields,
                }
            } );
        };
        like($@, qr/Value of 'components' element must have 'data_records' key-value pair/,
            "'new()' failed: 'components' element lacked 'data_records' element");
    }

    {
        local $@;
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => {
                    fields          => 'foo',
                    data_records    => $data_records,
                }
            } );
        };
        like($@,
            qr/Value of 'fields' element must be arrayref/,
            "'new()' failed: value of 'fields' element must be array ref");
    }

    {
        local $@;
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => {
                    fields          => { hash => ref},
                    data_records    => $data_records,
                }
            } );
        };
        like($@,
            qr/Value of 'fields' element must be arrayref/,
            "'new()' failed: value of 'fields' element must be array ref");
    }

    {
        local $@;
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => {
                    fields          => $fields,
                    data_records    => { my => $data_records },
                }
            } );
        };
        like($@,
            qr/Value of 'data_records' element must be arrayref/,
            "'new()' failed: value of 'data_records' element must be array ref");
    }

    {
        local $@;
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => {
                    fields          => $fields,
                    data_records    => [
                        [",Alpha", "", "", "", "", ""],
                        'foo'
                    ],
                }
            } );
        };
        like($@,
            qr/Each element in 'data_records' array must be arrayref/,
            "'new()' failed: element in array 'data_records' element must be array ref");
    }

    {
        local $@;
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => {
                    fields          => $fields,
                    data_records    => [
                        [",Alpha", "", "", "", "", ""],
                        { foo => 'bar' },
                    ],
                }
            } );
        };
        like($@,
            qr/Each element in 'data_records' array must be arrayref/,
            "'new()' failed: element in array 'data_records' element must be array ref");
    }

    {
        local $@;
        my $dupe_field = 'vertical';
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => {
                    fields        => ["id","parent_id","name",$dupe_field,$dupe_field,"wholesale_price","retail_price","is_actionable"],
                    data_records  => $data_records,
                },
            } );
        };
        like($@, qr/^Duplicate field '$dupe_field' observed in 'fields' array ref/,
            "'new()' died due to duplicate column name in 'fields' array ref");
    }

    {
        local $@;
        $expect = 'my_id';
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => {
                    fields        => $fields,
                    data_records  => $data_records,
                },
                id_col  => $expect,
            } );
        };
        like($@, qr/Could not locate columns in header to match required arguments.*id_col.*$expect/s,
            "new() died: id_col '$expect' not found in header row");
    }

    {
        local $@;
        $expect = 'my_parent_id';
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => {
                    fields        => $fields,
                    data_records  => $data_records,
                },
                parent_id_col  => $expect,
            } );
        };
        like($@, qr/Could not locate columns in header to match required arguments.*parent_id_col.*$expect/s,
            "new() died: parent_id_col '$expect' not found in header row");
    }

    {
        local $@;
        $expect = 'my_component_id';
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => {
                    fields        => $fields,
                    data_records  => $data_records,
                },
                component_col  => $expect,
            } );
        };
        like($@, qr/Could not locate columns in header to match required arguments.*component_col.*$expect/s,
            "new() died: component_col '$expect' not found in header row");
    }

    {
        local $@;
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => {
                    fields        => $fields,
                    data_records  => [
                      ["1","","Alpha","Auto","USD","","","0"],
                      ["3","1","Epsilon","Auto","USD","","","0"],
                      ["3","3","Kappa","Auto","USD","0.50","0.60","1"],
                      ["5","1","Zeta","Auto","USD","","","0"],
                      ["2","5","Lambda","Auto","USD","0.40","0.50","1"],
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
        };

        like($@, qr/^No duplicate entries are permitted in the 'id'column./s,
            "new() died due to duplicate values in column designated as 'id_col'");
        like($@, qr/2:\s+2/s, "More than one column had 'id' of 2");
        like($@, qr/3:\s+2/s, "More than one column had 'id' of 3");
    }

    {
        local $@;
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => {
                    fields        => $fields,
                    data_records  => [
                      ["1","","Alpha","Auto","USD","",""],
                      ["3","1","Epsilon","Auto","USD","","","0"],
                      ["4","3","Kappa","Auto","USD"],
                      ["5","1","Zeta","Auto","USD","","","0"],
                      ["6","5","Lambda","Auto","USD","0.40","0.50","1"],
                      ["7","5","Mu","Auto","USD","0.40","0.50","0"],
                      ["2","","Beta","Electronics","JPY","","","0"],
                      ["8","2","Eta","Electronics","JPY","0.35","0.45","1"],
                      ["9","2","Theta","Electronics","JPY","0.35","0.45","1"],
                      ["10","","Gamma","Travel","EUR","","","0"],
                      ["11","10","Iota","Travel","EUR","","","0"],
                      ["12","11","Nu","Travel","EUR","0.60","0.75","1"],
                      ["13","","Delta","Life Insurance","USD","0.25","0.30","1","more","less"],
                    ],
                },
            } );
        };

        like($@, qr/^Header row has \d+ columns.  The following records/s,
            "new() died due to wrong number of columns in one or more rows");
        like($@, qr/1:\s+7/s, "Identified record with too few columns");
        like($@, qr/4:\s+5/s, "Identified record with too few columns");
        like($@, qr/13:\s+10/s, "Identified record with too many columns");
    }

    {
        local $@;
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => {
                    fields        => $fields,
                    data_records  => [
                      ["1","","Alpha","Auto","USD","","","0"],
                      ["3","1","Epsilon","Auto","USD","","","0"],
                      ["4","3","Kappa","Auto","USD","0.50","0.60","1"],
                      ["5","1","Zeta","Auto","USD","","","0"],
                      ["6","14","Lambda","Auto","USD","0.40","0.50","1"],
                      ["7","5","Mu","Auto","USD","0.40","0.50","0"],
                      ["2","","Beta","Electronics","JPY","","","0"],
                      ["8","2","Eta","Electronics","JPY","0.35","0.45","1"],
                      ["9","2","Theta","Electronics","JPY","0.35","0.45","1"],
                      ["10","","Gamma","Travel","EUR","","","0"],
                      ["11","10","Iota","Travel","EUR","","","0"],
                      ["12","37","Nu","Travel","EUR","0.60","0.75","1"],
                      ["13","","Delta","Life Insurance","USD","0.25","0.30","1"],
                    ],
                },
            } );
        };
        like($@, qr/^For each record with a non-null value in the 'parent_id' column/s,
            "new() died due to parent_id column values without corresponding id records");
    }

    {
        local $@;
        eval {
            $obj = Parse::File::Taxonomy::Index->new( {
                components  => {
                    fields        => $fields,
                    data_records  => [
                      ["1","","Alpha","Auto","USD","","","0"],
                      ["3","1","Epsilon","Auto","USD","","","0"],
                      ["4","3","Kappa","Auto","USD","0.50","0.60","1"],
                      ["5","1","Epsilon","Auto","USD","","","0"],
                      ["6","5","Lambda","Auto","USD","0.40","0.50","1"],
                      ["7","5","Mu","Auto","USD","0.40","0.50","0"],
                      ["2","","Beta","Electronics","JPY","","","0"],
                      ["8","2","Eta","Electronics","JPY","0.35","0.45","1"],
                      ["9","2","Eta","Electronics","JPY","0.35","0.45","1"],
                      ["10","","Gamma","Travel","EUR","","","0"],
                      ["11","10","Iota","Travel","EUR","","","0"],
                      ["12","11","Nu","Travel","EUR","0.60","0.75","1"],
                      ["13","","Delta","Life Insurance","USD","0.25","0.30","1"],
                    ],
                },
            } );
        };
        like($@, qr/^No record with a non-null value in the 'parent_id' column/s,
            "new() died due to parent with children sharing same name");
    }

    {
        $obj = Parse::File::Taxonomy::Index->new( {
            components  => {
                fields          => $fields,
                data_records    => $data_records,
            }
        } );
        ok(defined $obj, "new() returned defined value");
        isa_ok($obj, 'Parse::File::Taxonomy::Index');
    }

}

