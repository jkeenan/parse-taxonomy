package Parse::File::Taxonomy::Index;
use strict;
use parent qw( Parse::File::Taxonomy );
use Carp;
use Text::CSV;
use Scalar::Util qw( reftype );
our $VERSION = '0.03';
use Parse::File::Taxonomy::Auxiliary qw(
    path_check_fields
    components_check_fields
);
#use Data::Dump;

=head1 NAME

Parse::File::Taxonomy::Index - Extract a taxonomy from a hierarchy inside a CSV file

=head1 SYNOPSIS

    use Parse::File::Taxonomy::Index;

    $source = "./t/data/alpha.csv";
    $obj = Parse::File::Taxonomy::Index->new( {
        file    => $source,
    } );

=cut

=head1 METHODS

=head2 C<new()>

=over 4

=item * Purpose

Parse::File::Taxonomy::Index constructor.

=item * Arguments

Single hash reference.  There are two possible interfaces: C<file> and C<components>.

=over 4

=item 1 C<file> interface

    $source = "./t/data/delta.csv";
    $obj = Parse::File::Taxonomy::Index->new( {
        file    => $source,
    } );

Elements in the hash reference are keyed on:

=over 4

=item * C<file>

Absolute or relative path to the incoming taxonomy file.
B<Required> for this interface.

=item * C<id_col>

The name of the column in the header row under which each data record's unique
ID can be found.  Defaults to C<id>.

=item * C<parent_id_col>

The name of the column in the header row under which each data record's parent
ID can be found.  (Will be empty in the case of top-level nodes, as they have
no parent.)  Defaults to C<parent_id>.

=item * C<component_col>

The name of the column in the header row under which, in each data record, there
is a found a string which differentiates that record from all other records
with the same parent ID.  Defaults to C<name>.

=item * Text::CSV options

Any other options which could normally be passed to C<Text::CSV->new()> will
be passed through to that module's constructor.  On the recommendation of the
Text::CSV documentation, C<binary> is always set to a true value.

=back

=item 2 C<components> interface

    $obj = Parse::File::Taxonomy::Index->new( {
        components  => {
            fields          => $fields,
            data_records    => $data_records,
        }
    } );

Elements in this hash are keyed on:

=over 4

=item * C<components>

This element is B<required> for the C<components> interface. The value of this
element is a hash reference with two keys, C<fields> and C<data_records>.
C<fields> is a reference to an array holding the field or column names for the
data set.  C<data_records> is a reference to an array of array references,
each of the latter arrayrefs holding one record or row from the data set.

=back

=back

=item * Return Value

Parse::File::Taxonomy::Index object.

=item * Exceptions

C<new()> will throw an exception under any of the following conditions:

=over 4

=item * Argument to C<new()> is not a reference.

=item * Argument to C<new()> is not a hash reference.

=item * Argument to C<new()> must have either 'file' or 'components' element but not both.

=item * Lack columns in header row to match requirements.

=item * Non-numeric entry in C<id> or C<parent_id> column.

=item * Duplicate entries in C<id> column.

=item * Number of fields in a data record does not match number in header row.

=item * Empty string in a C<component> column of a record.

=item * Unable to locate a record whose C<id> is the C<parent_id> of a different record.

=item * No records with same C<parent_id> may share value of C<component> column.

=item * C<file> interface

=over 4

=item * In the C<file> interface, unable to locate the file which is the value of the C<file> element.

=item * The same field is found more than once in the header row of the
incoming taxonomy file.

=item * Unable to open or close the incoming taxonomy file for reading.

=back

=item * C<components> interface

=over 4

=item * In the C<components> interface, C<components> element must be a hash reference with C<fields> and C<data_records> elements.

=item * C<fields> element must be array reference.

=item * C<data_records> element must be reference to array of array references.

=item * No duplicate fields in C<fields> element's array reference.

=back

=back

=back

=cut

sub new {
    my ($class, $args) = @_;
    my $data;

    croak "Argument to 'new()' must be hashref"
        unless (ref($args) and reftype($args) eq 'HASH');
    croak "Argument to 'new()' must have either 'file' or 'components' element"
        unless ($args->{file} or $args->{components});
    croak "Argument to 'new()' must have either 'file' or 'components' element but not both"
        if ($args->{file} and $args->{components});

    $data->{id_col}           = $args->{id_col}
                                ? delete $args->{id_col}
                                : 'id';
    $data->{parent_id_col}    = $args->{parent_id_col}
                                ? delete $args->{parent_id_col}
                                : 'parent_id';
    $data->{component_col}    = $args->{component_col}
                                ? delete $args->{component_col}
                                : 'name';

    if ($args->{components}) {
        croak "Value of 'components' element must be hashref"
            unless (ref($args->{components}) and reftype($args->{components}) eq 'HASH');
        for my $k ( qw| fields data_records | ) {
            croak "Value of 'components' element must have '$k' key-value pair"
                unless exists $args->{components}->{$k};
            croak "Value of '$k' element must be arrayref"
                unless (ref($args->{components}->{$k}) and
                    reftype($args->{components}->{$k}) eq 'ARRAY');
        }
        for my $row (@{$args->{components}->{data_records}}) {
            croak "Each element in 'data_records' array must be arrayref"
                unless (ref($row) and reftype($row) eq 'ARRAY');
        }
        _prepare_fields($data, $args->{components}->{fields}, 1);
        my $these_data_records = $args->{components}->{data_records};
        delete $args->{components};
        _prepare_data_records($data, $these_data_records, $args);
    }
    else {
        croak "Cannot locate file '$args->{file}'"
            unless (-f $args->{file});
        $data->{file}             = delete $args->{file};
        $args->{binary} = 1;
        my $csv = Text::CSV->new ( $args )
            or croak "Cannot use CSV: ".Text::CSV->error_diag ();
        open my $IN, "<", $data->{file}
            or croak "Unable to open '$data->{file}' for reading";
        my $header_ref = $csv->getline($IN);
        _prepare_fields($data, $header_ref);

        my $data_records = $csv->getline_all($IN);
        close $IN or croak "Unable to close after reading";
        _prepare_data_records($data, $data_records, $args);
    }

    while (my ($k,$v) = each %{$args}) {
        $data->{$k} = $v;
    }
    return bless $data, $class;
}

sub _prepare_fields {
    my ($data, $fields_ref, $components) = @_;
    if (! $components) {
        path_check_fields($data, $fields_ref);
        _check_required_columns($data, $fields_ref);
    }
    else { # 'components' interface
        components_check_fields($data, $fields_ref);
        _check_required_columns($data, $fields_ref);
    }
    $data->{fields} = $fields_ref;
    return $data;
}

sub _check_required_columns {
    my ($data, $fields_ref) = @_;
    my %col2idx = map { $fields_ref->[$_] => $_ } (0 .. $#{$fields_ref});
    my %missing_columns = ();
    my %main_columns = map { $_ => 1 } ( qw| id_col parent_id_col component_col | );
    for my $c ( keys %main_columns ) {
        if (! exists $col2idx{$data->{$c}}) {
            $missing_columns{$c} = $data->{$c};
        }
    }
    my $error_msg = "Could not locate columns in header to match required arguments:";
    for my $c (sort keys %missing_columns) {
        $error_msg .= "\n  $c: $missing_columns{$c}";
    }
    croak $error_msg if scalar keys %missing_columns;
    $data->{fields} = $fields_ref;
    for my $c (keys %main_columns) {
        $data->{$c.'_idx'} = $col2idx{$data->{$c}};
    }
    return $data;
}

sub _prepare_data_records {
    my ($data, $data_records, $args) = @_;
    # Confirm no duplicate entries in 'id_col'. DONE
    # Confirm all rows have same number of columns as header. DONE
    my $error_msg = '';
    my $field_count = scalar(@{$data->{fields}});
    my @non_numeric_id_records = ();
    my %ids_seen = ();
    my @bad_count_records = ();
    my @nameless_component_records = ();
    for my $rec (@{$data_records}) {
        if ($rec->[$data->{id_col_idx}] !~ m/^\d+$/) {
            push @non_numeric_id_records, [ $rec->[$data->{id_col_idx}], '' ];
        }
        if (length($rec->[$data->{parent_id_col_idx}]) and
            $rec->[$data->{parent_id_col_idx}] !~ m/^\d+$/
        ) {
            push @non_numeric_id_records, [
                $rec->[$data->{id_col_idx}],
                $rec->[$data->{parent_id_col_idx}]
            ];
        }
        $ids_seen{$rec->[$data->{id_col_idx}]}++;
        my $this_row_count = scalar(@{$rec});
        if ($this_row_count != $field_count) {
            push @bad_count_records,
                [ $rec->[$data->{id_col_idx}], $this_row_count ];
        }
        if (! length($rec->[$data->{component_col_idx}])) {
            push @nameless_component_records, $rec->[$data->{id_col_idx}];
        }
    }
    $error_msg = <<NON_NUMERIC_IDS;
Non-numeric entries are not permitted in the '$data->{id_col}' or '$data->{parent_id_col}' columns.
The following records each violate this restriction one or two times:
NON_NUMERIC_IDS
    for my $rec (@non_numeric_id_records) {
        $error_msg .= "  $data->{id_col}: $rec->[0]\t$data->{parent_id_col}: $rec->[1]\n";
    }
    croak $error_msg if @non_numeric_id_records;

    my @dupe_ids = ();
    for my $id (sort keys %ids_seen) {
        push @dupe_ids, $id if $ids_seen{$id} > 1;
    }
    $error_msg = <<ERROR_MSG_DUPE;
No duplicate entries are permitted in the '$data->{id_col}'column.
The following entries appear the number of times shown:
ERROR_MSG_DUPE
    for my $id (@dupe_ids) {
        $error_msg .= "  $id:" . sprintf("  %6s\n" => $ids_seen{$id});
    }
    croak $error_msg if @dupe_ids;

    $error_msg = <<ERROR_MSG_WRONG_COUNT;
Header row has $field_count columns.  The following records
(identified by the value in their '$data->{id_col}' columns)
have different counts:
ERROR_MSG_WRONG_COUNT
    for my $rec (@bad_count_records) {
        $error_msg .= "  $rec->[0]: $rec->[1]\n";
    }
    croak $error_msg if @bad_count_records;

    $error_msg = <<NAMELESS_COMPONENT;
Each data record must have a non-empty string in its 'component' column.
The following records (identified by the value in their '$data->{id_col}' columns)
lack valid components:
NAMELESS_COMPONENT
    for my $rec (@nameless_component_records) {
        $error_msg .= "  id: $rec\n";
    }
    croak $error_msg if @nameless_component_records;

    my %ids_missing_parents = ();
    for my $rec (@{$data_records}) {
        my $parent_id = $rec->[$data->{parent_id_col_idx}];
        if ( (length($parent_id)) and (! $ids_seen{$parent_id}) ) {
            $ids_missing_parents{$rec->[$data->{id_col_idx}]} = $parent_id;
        }
    }
    $error_msg = <<ERROR_MSG_MISSING_PARENT;
For each record with a non-null value in the '$data->{parent_id_col}' column,
there must be a record with that value in the '$data->{id_col}' column.
The following records (identified by the value in their '$data->{id_col}' columns)
appear to to have parent IDs which do not have records of their own:
ERROR_MSG_MISSING_PARENT
    for my $k (sort {$a <=> $b} keys %ids_missing_parents) {
        $error_msg .= "  $k: $ids_missing_parents{$k}\n";
    }
    croak $error_msg if scalar keys %ids_missing_parents;

    my %families = ();
    for my $rec (@{$data_records}) {
        if (length($rec->[$data->{parent_id_col_idx}])) {
            $families{$rec->[$data->{parent_id_col_idx}]}{$rec->[$data->{component_col_idx}]}++;
        }
    }
    $error_msg = <<ERROR_MSG_SIBLINGS_NAMED_SAME;
No record with a non-null value in the '$data->{parent_id_col}' column
may have two children with the same value in the '$data->{component_col}' column.
The following are violations:
ERROR_MSG_SIBLINGS_NAMED_SAME

    my $same_names = 0;
    for my $k (sort {$a <=> $b} keys %families) {
        for my $l (sort keys %{$families{$k}}) {
            if ($families{$k}{$l} > 1) {
                $error_msg .= "  $data->{parent_id_col}: $k|$data->{component_col}: $l|count of $data->{component_col}s: $families{$k}{$l}\n";
                $same_names++;
            }
        }
    }
    croak $error_msg if $same_names;

    $data->{data_records} = $data_records;
    return $data;
}

=head2 C<fields()>

=over 4

=item * Purpose

Identify the names of the columns in the taxonomy.

=item * Arguments

    my $fields = $self->fields();

No arguments; the information is already inside the object.

=item * Return Value

Reference to an array holding a list of the columns as they appear in the
header row of the incoming taxonomy file.

=item * Comment

Read-only.

=back

# Implemented in lib/Parse/File/Taxonomy.pm

=head2 C<data_records()>

=over 4

=item * Purpose

Once the taxonomy has been validated, get a list of its data rows as a Perl
data structure.

=item * Arguments

    $data_records = $self->data_records;

None.

=item * Return Value

Reference to array of array references.  The array will hold the data records
found in the incoming taxonomy file in their order in that file.

=item * Comment

Does not contain any information about the fields in the taxonomy, so you
should probably either (a) use in conjunction with C<fields()> method above;
or (b) use C<fields_and_data_records()>.

=back

# Implemented in lib/Parse/File/Taxonomy.pm

=cut

=head2 C<get_field_position()>

=over 4

=item * Purpose

Identify the index position of a given field within the header row.

=item * Arguments

    $index = $obj->get_field_position('income');

Takes a single string holding the name of one of the fields (column names).

=item * Return Value

Integer representing the index position (counting from C<0>) of the field
provided as argument.  Throws exception if the argument is not actually a
field.

=back

=cut

# Implemented in lib/Parse/File/Taxonomy.pm

=head2 Accessors

The following methods provide information about key columns in a
Parse::File::Taxonomy::Path object.  The key columns are those which hold the
ID, parent ID and component information.  They take no arguments.  The methods
whose names end in C<_idx> return integers, as they return the index position
of the column in the header row.  The other methods return strings.

    $index_of_id_column = $self->id_col_idx;

    $name_of_id_column = $self->id_col;

    $index_of_parent_id_column = $self->parent_id_col_idx;

    $name_of_parent_id_column = $self->parent_id_col;

    $index_of_component_column = $self->component_col_idx;

    $name_of_component_column = $self->component_col;

=cut

sub id_col_idx {
    my $self = shift;
    return $self->{id_col_idx};
}

sub id_col {
    my $self = shift;
    return $self->{id_col};
}

sub parent_id_col_idx {
    my $self = shift;
    return $self->{parent_id_col_idx};
}

sub parent_id_col {
    my $self = shift;
    return $self->{parent_id_col};
}

sub component_col_idx {
    my $self = shift;
    return $self->{component_col_idx};
}

sub component_col {
    my $self = shift;
    return $self->{component_col};
}

=head2 C<pathify()>

=over 4

=item * Purpose

Generate a new Perl data structure which holds the same information as a
Parse::File::Taxonomy::Index object but which expresses the route from the
root node to a given branch or leaf node as either a separator-delimited
string (as in the C<path> column of a Parse::File::Taxonomy::Path object) or
as an array reference holding the list of names which delineate that route.

Another way of expressing this:  Transform a taxonomy-by-index to a
taxonomy-by-path.

Example:  Suppose we have a CSV file which serves as a taxonomy-by-index for
this data:

    "id","parent_id","name","is_actionable"
    "1","","Alpha","0"
    "2","","Beta","0"
    "3","1","Epsilon","0"
    "4","3","Kappa","1"
    "5","1","Zeta","0"
    "6","5","Lambda","1"
    "7","5","Mu","0"
    "8","2","Eta","1"
    "9","2","Theta","1"

Instead of having the route from the root node to a given node be represented
B<implicitly> by following C<parent_id>s up the tree, suppose we want that
route to be represented by a string.  Assuming that we work with default
column names, that would mean representing the information currently spread
out among the C<id>, C<parent_id> and C<name> columns in a single C<path>
column which, by default, would hold an array reference.

    $source = "./t/data/theta.csv";
    $obj = Parse::File::Taxonomy::Index->new( {
        file    => $source,
    } );

    $taxonomy_with_path_as_array = $obj->pathify;

Yielding:

    [
      ["path", "is_actionable"],
      [["", "Alpha"], 0],
      [["", "Beta"], 0],
      [["", "Alpha", "Epsilon"], 0],
      [["", "Alpha", "Epsilon", "Kappa"], 1],
      [["", "Alpha", "Zeta"], 0],
      [["", "Alpha", "Zeta", "Lambda"], 1],
      [["", "Alpha", "Zeta", "Mu"], 0],
      [["", "Beta", "Eta"], 1],
      [["", "Beta", "Theta"], 1],
    ]

If we wanted the path information represented as a string rather than an array
reference, we would say:

    $taxonomy_with_path_as_string = $obj->pathify( { as_string => 1 } );

Yielding:

    [
      ["path", "is_actionable"],
      ["|Alpha", 0],
      ["|Beta", 0],
      ["|Alpha|Epsilon", 0],
      ["|Alpha|Epsilon|Kappa", 1],
      ["|Alpha|Zeta", 0],
      ["|Alpha|Zeta|Lambda", 1],
      ["|Alpha|Zeta|Mu", 0],
      ["|Beta|Eta", 1],
      ["|Beta|Theta", 1],
    ]

If we are providing a true value to the C<as_string> key, we also get to
choose what character to use as the separator in the C<path> column.

    $taxonomy_with_path_as_string_different_path_col_sep =
        $obj->pathify( {
            as_string       => 1,
            path_col_sep    => '~~',
         } );

Yields:

    [
      ["path", "is_actionable"],
      ["~~Alpha", 0],
      ["~~Beta", 0],
      ["~~Alpha~~Epsilon", 0],
      ["~~Alpha~~Epsilon~~Kappa", 1],
      ["~~Alpha~~Zeta", 0],
      ["~~Alpha~~Zeta~~Lambda", 1],
      ["~~Alpha~~Zeta~~Mu", 0],
      ["~~Beta~~Eta", 1],
      ["~~Beta~~Theta", 1],
    ]

Finally, should we want the C<path> column in the returned arrayref to be
named something other than I<path>, we can provide a value to the C<path_col>
key.

    [
      ["foo", "is_actionable"],
      [["", "Alpha"], 0],
      [["", "Beta"], 0],
      [["", "Alpha", "Epsilon"], 0],
      [["", "Alpha", "Epsilon", "Kappa"], 1],
      [["", "Alpha", "Zeta"], 0],
      [["", "Alpha", "Zeta", "Lambda"], 1],
      [["", "Alpha", "Zeta", "Mu"], 0],
      [["", "Beta", "Eta"], 1],
      [["", "Beta", "Theta"], 1],
    ]

item * Arguments

Optional single hash reference.  If provided, the following keys may be used:

=over 4

=item * C<path_col>

User-supplied name for column holding path information in the returned array
reference.  Defaults to C<path>.

=item * C<as_string>

Boolean.  If supplied with a true value, path information will be represented
as a separator-delimited string rather than an array reference.

=item * C<path_col_sep>

User-supplied string to be used to separate the parts of the route when
C<as_string> is called with a true value.  Not meaningful unless C<as_string>
is true.

=back

=item * Return Value

Reference to an array of array references.  The first element in the array
will be a reference to an array of field names.  Each succeeding element will
be a reference to an array holding data for one record in the original
taxonomy.  The path data will be represented, by default, as an array
reference built up from the component (C<name>) column in the original
taxonomy, but if C<as_string> is selected, the path data in all non-header
elements will be a separator-delimited string.

=back

=cut

sub pathify {
    my ($self, $args) = @_;
    if (defined $args) {
        unless (ref($args) and (reftype($args) eq 'HASH')) {
            croak "Argument to pathify() must be hash ref";
        }
        my %permissible_args = map { $_ => 1 } ( qw| path_col as_string path_col_sep | );
        for my $k (keys %{$args}) {
            croak "'$k' is not a recognized key for pathify() argument hashref"
                unless $permissible_args{$k};
        }
        if ($args->{path_col_sep} and not $args->{as_string}) {
            croak "Supplying a value for key 'path_col_step' is only valid when also supplying true value for 'as_string'";
        }
    }
    $args->{path_col} = defined($args->{path_col}) ? $args->{path_col} : 'path';
    if ($args->{as_string}) {
        $args->{path_col_sep} = defined($args->{path_col_sep}) ? $args->{path_col_sep} : '|';
    }

    my @rewritten = ();
    my @fields_in  = @{$self->fields};
    my @fields_out = ( $args->{path_col} );
    for my $f (@fields_in) {
        unless (
            ($f eq $self->id_col) or
            ($f eq $self->parent_id_col) or
            ($f eq $self->component_col)
        ) {
            push @fields_out, $f;
        }
    }
    push @rewritten, \@fields_out;

    my %colsin2idx  = map { $fields_in[$_]  => $_ } (0 .. $#fields_in);

    my %hashed_data =  map { $_->[$self->id_col_idx] => {
        parent_id       => $_->[$self->parent_id_col_idx],
        component       => $_->[$self->component_col_idx],
    } } @{$self->data_records};

    my @this_path = ();
    my $code;
    $code = sub {
        my $id = shift;
        push @this_path, $hashed_data{$id}{component};
        my $parent_id = $hashed_data{$id}{parent_id};
        if (length($parent_id)) {
            &{$code}($parent_id);
        }
        else {
            push @this_path, '';
        }
        return;
    };
    for my $rec (@{$self->data_records}) {
        my @new_record;
        &{$code}($rec->[$self->id_col_idx]);
        my $path_as_array_ref = [ reverse @this_path ];
        if ($args->{as_string}) {
            push @new_record,
                join($args->{path_col_sep} => @{$path_as_array_ref});
        }
        else {
            push @new_record, $path_as_array_ref;
        }
        for my $f (grep { $_ ne $args->{path_col} } @fields_out) {
            push @new_record, $rec->[$colsin2idx{$f}];
        }
        push @rewritten, \@new_record;
        @this_path = ();
    }
    return \@rewritten;
}

1;

# vim: formatoptions=crqot
