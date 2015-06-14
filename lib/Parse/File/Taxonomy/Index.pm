package Parse::File::Taxonomy::Index;
use strict;
use parent qw( Parse::File::Taxonomy );
use Carp;
use Text::CSV;
use Scalar::Util qw( reftype );
our $VERSION = '0.02';
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

# Arguments needed for validation of incoming file:
# file              # path to incoming file
# id_col            # default 'id'
# parent_id_col     # default 'parent_id'
# component_col     # default 'name'
#
# Arguments needed to create outgoing file:
# outfile           # path to outgoing file; location must be writable
# path_col          # default 'full_path'
#                       # cannot be used if there exists an incoming column
#                       named 'full_path'
# path_col_idx      # integer; default 0

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
    $data->{path_col} = $data->{fields}->[$data->{path_col_idx}];
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
    my $field_count = scalar(@{$data->{fields}});
    my @bad_count_records = ();
    my %ids_seen = ();
    for my $rec (@{$data_records}) {
        $ids_seen{$rec->[$data->{id_col_idx}]}++;
        my $this_row_count = scalar(@{$rec});
        if ($this_row_count != $field_count) {
            push @bad_count_records,
                [ $rec->[$data->{id_col_idx}], $this_row_count ];
        }
    }
    my @dupe_ids = ();
    for my $id (sort keys %ids_seen) {
        push @dupe_ids, $id if $ids_seen{$id} > 1;
    }
    my $error_msg = <<ERROR_MSG_DUPE;
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

=head2 C<data_records_path_components()>

=over 4

=item * Purpose

Once the taxonomy has been validated, get a list of its data rows as a Perl
data structure.  In each element of this list, the path is now represented as
an array reference rather than a string.

=item * Arguments

    $data_records_path_components = $self->data_records_path_components;

None.

=item * Return Value

Reference to array of array references.  The array will hold the data records
found in the incoming taxonomy file in their order in that file.

=item * Comment

Does not contain any information about the fields in the taxonomy, so you may
wish to use this method either (a) use in conjunction with C<fields()> method
above; or (b) use C<fields_and_data_records_path_components()>.

=back

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

1;
