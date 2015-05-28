package Parse::File::Taxonomy;
use strict;
use Carp;
use Text::CSV;
use Scalar::Util qw( reftype );
our $VERSION = '0.01';
use Data::Dump;


=head1 NAME

Parse::File::Taxonomy - Validate a file for use as a taxonomy

=head1 SYNOPSIS

    use Parse::File::Taxonomy;

    $source = "./t/data/alpha.csv";
    $obj = Parse::File::Taxonomy->new( {
        file    => $source,
    } );

    $hashified_taxonomy = $obj->hashify_taxonomy();

=head1 DESCRIPTION

This module takes as input a plain-text file, verifies that it can be used as
a taxonomy, then creates a Perl data structure representing that taxonomy.

=head2 Taxonomy: definition

For the purpose of this module, a B<taxonomy> is defined as a tree-like data
structure with a root node, zero or more branch (child) nodes, and one or more
leaf nodes.  The root node and each branch node must have at least one child
node, but leaf nodes have no child nodes.  The number of branches
between a leaf node and the root node is variable.

B<Diagram 1:>

                               Root
                                |
                  ----------------------------------------------------
                  |                            |            |        |
               Branch                       Branch       Branch     Leaf
                  |                            |            |
       -------------------------         ------------       |
       |                       |         |          |       |
    Branch                  Branch     Leaf       Leaf   Branch
       |                       |                            |
       |                 ------------                       |
       |                 |          |                       |
     Leaf              Leaf       Leaf                    Leaf

=head2 Taxonomy File:  definition

For the purpose of this module, a B<taxonomy file> is (a) a CSV file in which
one column holds data on the position of each record within the taxonomy and
(b) in which each node in the tree other than the root node is uniquely
represented by a record within the file.

=head3 CSV

B<"CSV">, strictly speaking, refers to B<comma-separated values>:

    path,nationality,gender,age,income,id_no

For the purpose of this module, however, column separators in a taxonomy file
may be any user-specified character handled by the F<Text-CSV> library.
Formats frequently observed are B<tab-separated values>:

    path	nationality	gender	age	income	id_no

and B<pipe-separated values>:

    path|nationality|gender|age|income|id_no

The documentation for F<Text-CSV> comments that the CSV format could <I"...
perhaps better [be] called ASV (anything separated values)">, but we shall for
convenience use "CSV" herein regardless of the specific delimiter.

Since it is often the case that the characters used as column separators may
occur within the data recorded in the columns as well, it is customary to
quote either all columns:

    "path","nationality","gender","age","income","id_no"

or, at the very least, all columns which can hold
data other than pure integers or floating-point numbers:

    "path","nationality","gender",age,income,id_no

=head3 Tree structure

To qualify as a taxonomy file, it is not sufficient for a file to be in CSV
format.  In each non-header record in that file, one column must hold data
capable of exactly specifying the record's position in the taxonomy, I<i.e.,>
the route or B<path> from the root node to the node being represented by that
record.  That data must itself be in delimiter-separated format.  Each
non-root node in the taxonomy must have exactly one record holding its path
data.  Within that path column the value corresponding to the root node need
not be specified, I<i.e.,> may be represented by an empty string.

Let's rewrite Diagram 1 with values to make this clear.

B<Diagram 2:>

                               ""
                                |
                  ----------------------------------------------------
                  |                            |            |        |
                Alpha                        Beta         Gamma    Delta
                  |                            |            |
       -------------------------         ------------       |
       |                       |         |          |       |
    Epsilon                  Zeta       Eta       Theta   Iota
       |                       |                            |
       |                 ------------                       |
       |                 |          |                       |
     Kappa            Lambda        Mu                      Nu

Let us suppose that our taxonomy file held comma-separated, quoted records.
Let us further supposed that the column holding taxonomy paths was, not
surprisingly, called C<path> and that the separator within the C<path> column
was a pipe (C<|>) character.  Let us further suppose that for now we are not
concerned with the data in any columns other than C<path> so that, for purpose
of illustration, they will hold empty (albeit quoted) string.

Then the taxonomy file describing the tree in
Diagram 2 would look like this:

    "path","nationality","gender","age","income","id_no"
    "|Alpha","","","","",""
    "|Alpha|Epsilon","","","","",""
    "|Alpha|Epsilon|Kappa","","","","",""
    "|Alpha|Zeta","","","","",""
    "|Alpha|Zeta|Lambda","","","","",""
    "|Alpha|Zeta|Mu","","","","",""
    "|Beta","","","","",""
    "|Beta|Eta","","","","",""
    "|Beta|Theta","","","","",""
    "|Gamma","","","","",""
    "|Gamma|Iota","","","","",""
    "|Gamma|Iota|Nu","","","","",""
    "|Delta","","","","",""

Note that while in the C<|Gamma> branch we ultimately have only one leaf node,
C<|Gamma|Iota|Nu>, we require separate records in the taxonomy file for
C<|Gamma> and C<|Gamma|Iota>.  To put this another way, the existence of a
C<Gamma|Iota|Nu> leaf must not be taken to "auto-vivify" C<|Gamma> and
C<|Gamma|Iota> nodes.  Each non-root node must be explicitly represented in
the taxonomy file for the file to be considered valid.

Note further that there is no restriction on the values of the B<components> of
the C<path> across records.  It only the B<full> path that must be unique.
Let us illustrate that by modifying the data in Diagram 2:

B<Diagram 3:>

                               ""
                                |
                  ----------------------------------------------------
                  |                            |            |        |
                Alpha                        Beta         Gamma    Delta
                  |                            |            |
       -------------------------         ------------       |
       |                       |         |          |       |
    Epsilon                  Zeta       Eta       Theta   Iota
       |                       |                            |
       |                 ------------                       |
       |                 |          |                       |
     Kappa            Lambda        Mu                    Delta

Here we have two leaf nodes each named C<Delta>.  However, we follow different
paths from the root node to get to each of them.  The taxonomy file
representing this tree would look like this:

    "path","nationality","gender","age","income","id_no"
    "|Alpha","","","","",""
    "|Alpha|Epsilon","","","","",""
    "|Alpha|Epsilon|Kappa","","","","",""
    "|Alpha|Zeta","","","","",""
    "|Alpha|Zeta|Lambda","","","","",""
    "|Alpha|Zeta|Mu","","","","",""
    "|Beta","","","","",""
    "|Beta|Eta","","","","",""
    "|Beta|Theta","","","","",""
    "|Gamma","","","","",""
    "|Gamma|Iota","","","","",""
    "|Gamma|Iota|Delta","","","","",""
    "|Delta","","","","",""

=head2 Taxonomy Validation

The C<Parse::File::Taxonomy> constructor, C<new()>, will probe a taxonomy file
provided to it as an argument to determine whether it can be considered a
valid taxonomy according to the description provided above.

TODO:  C<Parse::File::Taxonomy->new() should also be able to accept a reference to an
array of CSV records already held in memory.

TODO:  What would it mean for C<Parse::File::Taxonomy->new() to accept a
filehandle as an argument, rather than a file?  Would that be difficult to
implement?

The user of this library, however, must be permitted to write B<additional
user-specified validation rules> which will be applied to a taxonomy by means
of a method called on a Parse::File::Taxonomy object.  Should the file fail to meet those rules, the
user may choose not to proceed further even though the taxonomy meets the
basic validation criteria implemented in the constructor.  This method will
probably take a reference to an array of subroutines references as its
argument.  Each such code reference will be a user-defined rule which the
taxonomy must obey.  The method will apply each code reference to the taxonomy in
sequence and will return with a true value if and only if all the individual
criteria return true as well.

=head2 The Parse::File::Taxonomy Object

B<Note:>  This section is mostly the author thinking out loud.

What methods would we like to be able to call on an object returned by the
C<Parse::File::Taxonomy> constructor?

The mere fact that C<new()> returns an object should suffice to say that the
taxonomy file submitted represents a valid taxonomy.  Hence, we should B<not>
need an C<is_valid()> method.

If we wanted to have a method which returned a reference to a hash depicting
the tree structure, we would have to take into consideration that in Perl we
can auto-vivify intermediate levels of a multi-level hash:

Returning to the taxonomy file depicting the data in Diagram 2:

    my $hashref = {
        'Alpha' => {
            'Epsilon' => {
                'Kappa'     => 1,
            },
            'Zeta' => {
                'Lambda'    => 1,
                'Mu'        => 1,
            },
        },
        'Beta'  => {
            'Eta'   => 1,
            'Theta' => 1,
        },
        'Gamma' => {
            'Iota'  => {
                'Nu'        => 1,
            },
        },
        'Delta' => 1,
    };

This data structure does a good job of representing the 7 leaf nodes in the
taxonomy.  But suppose we wanted to represent all the other, non-C<path> fields in
the submitted taxonomy file.  We could assign a hashref of those fields to
each leaf node, instead of assigning C<1>.  But there wouldn't be an elegant way to represent
those fields for the branch nodes.  The following doesn't seem right:

    my $inelegant_hashref = {
        'Alpha' => {
            other_fields    => { ... },
            children        => {
                'Epsilon' => {
                    other_fields    => { ... },
                    children        => {
                        'Kappa'         => { ... },
                    }
                },
                'Zeta' => {
                    other_fields    => { ... },
                    children        => {
                        'Lambda'        => { ... },
                        'Mu'            => { ... },
                    }
                },
            },
        },
        # ...
    };

What we probably want is a hash which represents the entire path for a given
record in the taxonomy in the B<key> of a hash element, thereby permitting the other
columns in a given record in the taxonomy file to be represented in the
B<value> of that element.  We would want the user to be able to supply a
string to server as delimiter for the components of that key (we would supply
a convenient default) and we would enable the user to supply some string to
denote the root level (which would otherwise default to not used to formulate
the key).

Suppose we say that we will use pipe as the default delimiter in this method.
Then the taxonomy file representing Diagram 2 would be hashified as follows:

    $hashref = $self->hashify_taxonomy();

This would produce:

    {
        "Alpha"                 => { ... },
        "Alpha|Epsilon"         => { ... },
        "Alpha|Epsilon|Kappa"   => { ... },
        "Alpha|Zeta"            => { ... },
        "Alpha|Zeta|Lambda"     => { ... },
        "Alpha|Zeta|Mu"         => { ... },
        "Beta"                  => { ... },
        "Beta|Eta"              => { ... },
        "Beta|Theta"            => { ... },
        "Gamma"                 => { ... },
        "Gamma|Iota"            => { ... },
        "Gamma|Iota|Delta"      => { ... },
        "Delta"                 => { ... },
    };

That is better.  We have 13 elements in the hash, each corresponding to one of
the 13 data records in the taxonomy file submitted.

Suppose the user wanted to use the string C< - > in the key.  The method would
then be called:

    $hashref = $self->hashify_taxonomy( {
        key_delim   => q{ - },
    } );

This would produce:

    {
        "Alpha"                     => { ... },
        "Alpha - Epsilon"           => { ... },
        "Alpha - Epsilon - Kappa"   => { ... },
        "Alpha - Zeta"              => { ... },
        "Alpha - Zeta - Lambda"     => { ... },
        "Alpha - Zeta - Mu"         => { ... },
        "Beta"                      => { ... },
        "Beta - Eta"                => { ... },
        "Beta - Theta"              => { ... },
        "Gamma"                     => { ... },
        "Gamma - Iota"              => { ... },
        "Gamma - Iota - Delta"      => { ... },
        "Delta"                     => { ... },
    };

If the user wanted to denote the root node with the string C<All Suppliers>
and use the string C<|||> as the delimiter in the key, the method would be
called like this:

    $hashref = $self->hashify_taxonomy( {
        key_delim   => q{|||},
        root_str    => q{All Suppliers},
    } );

This would produce:

    {
        "All Suppliers|||Alpha"                     => { ... },
        "All Suppliers|||Alpha|||Epsilon"           => { ... },
        "All Suppliers|||Alpha|||Epsilon|||Kappa"   => { ... },
        "All Suppliers|||Alpha|||Zeta"              => { ... },
        "All Suppliers|||Alpha|||Zeta|||Lambda"     => { ... },
        "All Suppliers|||Alpha|||Zeta|||Mu"         => { ... },
        "All Suppliers|||Beta"                      => { ... },
        "All Suppliers|||Beta|||Eta"                => { ... },
        "All Suppliers|||Beta|||Theta"              => { ... },
        "All Suppliers|||Gamma"                     => { ... },
        "All Suppliers|||Gamma|||Iota"              => { ... },
        "All Suppliers|||Gamma|||Iota|||Delta"      => { ... },
        "All Suppliers|||Delta"                     => { ... },
    };

=head1 METHODS

=head2 C<new()>

=over 4

=item * Purpose

Parse::File::Taxonomy constructor.

=item * Arguments

    $source = "./t/data/alpha.csv";
    $obj = Parse::File::Taxonomy->new( {
        file    => $source,
    } );

Single hash reference.  Elements in that hash are keyed on:

=over 4

=item * C<file>

Absolute or relative path to the incoming taxonomy file.  Currently
B<required> (but this may change if we implement ability to use a list of CSV
strings instead of a file).

=item * C<path_col_idx>

If the column to be used as the "path" column in the incoming taxonomy file is
B<not> the first column, this option must be set to the integer representing
the "path" column's index position (count starts at 0).  Optional; defaults to C<0>.

=item * C<path_col_sep>

If the string used to distinguish components of the path in the path column in
the incoming taxonomy file is not a pipe (C<|>), this option must be set.
Optional; defaults to C<|>.

=item *  Text::CSV options

Any other options which could normally be passed to C<Text::CSV->new()> will
be passed through to that module's constructor.  On the recommendation of the
Text::CSV documentation, C<binary> is always set to a true value.

=back

=item * Return Value

Parse::File::Taxonomy object.

=item * Comment

C<new()> will throw an exception under any of the following conditions:

=over 4

=item * Argument to C<new()> is not a reference.

=item * Argument to C<new()> is not a hash reference.

=item * Unable to locate the file which is the value of the C<file> element.

=item * Argument to C<path_col_idx> element is not an integer.

=item * Argument to C<path_col_idx> is greater than the index number of the
last element in the header row of the incoming taxonomy file, I<i.e.,> the
C<path_col_idx> is wrong.

=item * The same field is found more than once in the header row of the
incoming taxonomy file.

=item * Unable to open or close the incoming taxonomy file for reading.

=item * In the column designated as the "path" column, the same value is
observed more than once.

=item * A non-parent node's parent node cannot be located in the incoming taxonomy file.

=item * A data row has a number of fields different from the number of fields
in the header row.

=back

=back

=cut

sub new {
    my ($class, $args) = @_;
    my %data;

    croak "Argument to 'new()' must be hashref"
        unless (ref($args) and reftype($args) eq 'HASH');
    croak "Argument to 'new()' must have 'file' element" unless $args->{file};
    croak "Cannot locate file '$args->{file}'"
        unless (-f $args->{file});
    $data{file} = delete $args->{file};

    if (exists $args->{path_col_idx}) {
        croak "Argument to 'path_col_idx' must be integer"
            unless $args->{path_col_idx} =~ m/^\d+$/;
    }
    $data{path_col_idx} = delete $args->{path_col_idx} || 0;
    $data{path_col_sep} = exists $args->{path_col_sep}
        ? $args->{path_col_sep}
        : '|';
    if (exists $args->{path_col_sep}) {
        $data{path_col_sep} = $args->{path_col_sep};
        delete $args->{path_col_sep};
    }
    else {
        $data{path_col_sep} = '|';
    }

    # We've now handled all the Parse::File::Taxonomy-specific options.
    # Any remaining options are assumed to be intended for Text::CSV::new().

    $args->{binary} = 1;
    my $csv = Text::CSV->new ( $args )
        or croak "Cannot use CSV: ".Text::CSV->error_diag ();
    open my $IN, "<", $data{file}
        or croak "Unable to open '$data{file}' for reading";
    my $header_ref = $csv->getline($IN);

    croak "Argument to 'path_col_idx' exceeds index of last field in header row in '$data{file}'"
        if $data{path_col_idx} > $#{$header_ref};

    my %header_fields_seen;
    for (@{$header_ref}) {
        if (exists $header_fields_seen{$_}) {
            croak "Duplicate field '$_' observed in '$data{file}'";
        }
        else {
            $header_fields_seen{$_}++;
        }
    }
    $data{fields} = $header_ref;
    my $field_count = scalar(@{$data{fields}});
    $data{path_col} = $data{fields}->[$data{path_col_idx}];

    my $all_records = $csv->getline_all($IN);
    close $IN or croak "Unable to close after reading";


    # Confirm no duplicate entries in column holding path:
    # Confirm all rows have same number of columns as header:
    my @bad_count_records = ();
    my %paths_seen = ();
    for my $rec (@{$all_records}) {
        $paths_seen{$rec->[$data{path_col_idx}]}++;
        my $this_row_count = scalar(@{$rec});
        if ($this_row_count != $field_count) {
            push @bad_count_records,
                [ $rec->[$data{path_col_idx}], $this_row_count ];
        }
    }
    my @dupe_paths = ();
    for my $path (sort keys %paths_seen) {
        push @dupe_paths, $path if $paths_seen{$path} > 1;
    }
    my $error_msg = <<ERROR_MSG_DUPE;
No duplicate entries are permitted in column designated as path.
The following entries appear the number of times shown:
ERROR_MSG_DUPE
    for my $path (@dupe_paths) {
        $error_msg .= "  $path:" . sprintf("  %6s\n" => $paths_seen{$path});
    }
    croak $error_msg if @dupe_paths;

    $error_msg = <<ERROR_MSG_WRONG_COUNT;
Header row had $field_count records.  The following records had different counts:
ERROR_MSG_WRONG_COUNT
    for my $rec (@bad_count_records) {
        $error_msg .= "  $rec->[0]: $rec->[1]\n";
    }
    croak $error_msg if @bad_count_records;

    # Confirm each node appears in taxonomy:
    my $path_args = { map { $_ => $args->{$_} } keys %{$args} };
    $path_args->{sep_char} = $data{path_col_sep};
    my $path_csv = Text::CSV->new ( $path_args )
        or croak "Cannot use CSV: ".Text::CSV->error_diag ();
    my %missing_parents = ();
    for my $path (sort keys %paths_seen) {
        my $status  = $path_csv->parse($path);
        my @columns = $path_csv->fields();
        if (@columns > 2) {
            my $parent =
                join($path_args->{sep_char} => @columns[0 .. ($#columns - 1)]);
            unless (exists $paths_seen{$parent}) {
                $missing_parents{$path} = $parent;
            }
        }
    }
    $error_msg = <<ERROR_MSG_ORPHAN;
Each node in the taxonomy must have a parent.
The following nodes lack the expected parent:
ERROR_MSG_ORPHAN
    for my $path (sort keys %missing_parents) {
        $error_msg .= "  $path:  $missing_parents{$path}\n";
    }
    croak $error_msg if scalar(keys %missing_parents);

    while (my ($k,$v) = each %{$args}) {
        $data{$k} = $v;
    }
    my @all;
    for my $row (@{$all_records}) {
        my $rowhash;
        $rowhash->{data} = {
            map { $data{fields}->[$_] => $row->[$_] } (0 .. $#{$row})
        };
        $rowhash->{key} = $row->[$data{path_col_idx}];
        push @all, $rowhash;
    }
    my %child_counts = map { $_->{key} => 0  } @all;
    for my $node (keys %child_counts) {
        for my $other_node ( grep { ! m/^\Q$node\E$/ } keys %child_counts) {
            $child_counts{$node}++
                if $other_node =~ m/^\Q$node$args->{path_col_sep}\E/;
        }
    }
    $data{all} = \@all;
    $data{child_counts} = \%child_counts;
    return bless \%data, $class;
}

=head2 C<hashify_taxonomy()>

=over 4

=item * Purpose

Turn a validated taxonomy into a Perl hash keyed on the column designated as
the path column.

=item * Arguments

    $hashref = $self->hashify_taxonomy();

Takes an optional hashref holding a list of any of the following elements:

=over 4

=item * C<retain_leading_path_col_sep>

Boolean, defaulting to C<0>.  Typically, in hashifying the taxonomy we can
omit the name, if any, of the root node because it's the same for all entries.
In that case, there's probably not much to be gained by retaining the first
instance of the C<path_col_sep>.  So, typically, a path in the incoming
taxonomy file represented by C<|Alpha|Beta|Gamma> would be represented as key
C<Alpha|Beta|Gamma>.

However, should you wish to retain that leading C<path_col_sep>, set this
switch to a Perl-true value.

    $hashref = $self->hashify_taxonomy( {
        retain_leading_path_col_sep => 1,
    } );

In the example above, this would result in a key spelled C<|Alpha|Beta|Gamma>.

Note further that if the C<root_str> switch is set to a true value, any
setting to C<retain_leading_path_col_sep> will be ignored.

=item * C<key_delim>

A string which will be used in composing the key of the hashref returned by
this method.  The user may select this key if she does not want to use the
value found in the incoming CSV file (which by default will be the pipe
character (C<|>) and which may be overridden with the C<path_col_sep> argument
to C<new()>.

    $hashref = $self->hashify_taxonomy( {
        key_delim   => q{ - },
    } );

In the above variant, a path that in the incoming taxonomy file was
represented by C<|Alpha|Beta|Gamma> will in C<$hashref> be represented by
C<Alpha - Beta - Gamma>.

=item * C<root_str>

A string which will be used in composing the key of the hashref returned by
this method.  The user will set this switch if she wishes to have the root
note explicitly represented.  Using this switch will automatically cause
C<retain_leading_path_col_sep> to be ignored.

Suppose the user wished to have C<All Suppliers> be the text for the root
node.  Suppose further that the user wanted to use the string C< - > as the
delimiter within the key.

    $hashref = $self->hashify_taxonomy( {
        root_str    => q{All Suppliers},
        key_delim   => q{ - },
    } );

Then incoming path C<|Alpha|Beta|Gamma> would be keyed as:

    All Suppliers - Alpha - Beta - Gamma

=back

=item * Return Value

Hash reference.  The number of elements in this hash should be equal to the
number of non-header records in the taxonomy.

=back

=cut

sub hashify_taxonomy {
    my ($self, $args) = @_;
    if (defined $args) {
        croak "Argument to 'new()' must be hashref"
            unless (ref($args) and reftype($args) eq 'HASH');
    }
    my %hashified;
    for my $rec (@{$self->{all}}) {
        my $k = $rec->{key};
        if ($args->{root_str}) {
            $k = $args->{root_str} . $k;
        }
        else {
            if (! $args->{retain_leading_path_col_sep}) {
                $k =~ s/^\Q$self->{path_col_sep}\E(.*)/$1/;
            }
        }
        if ($args->{key_delim}) {
            $k =~ s/\Q$self->{path_col_sep}\E/$args->{key_delim}/g;
        }
        $hashified{$k} = $rec->{data};
    }
    return \%hashified;
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

=cut

sub fields {
    my $self = shift;
    return $self->{fields};
}

=head2 C<path_col_idx()>

=over 4

=item * Purpose

Identify the index position (count starts at 0) of the column in the incoming
taxonomy file which serves as the path column.

=item * Arguments

    my $path_col_idx = $self->path_col_idx;

No arguments; the information is already inside the object.

=item * Return Value

Integer in the range from 0 to 1 less than the number of columns in the header
row.

=item * Comment

Read-only.

=back

=cut

sub path_col_idx {
    my $self = shift;
    return $self->{path_col_idx};
}

=head2 C<path_col()>

=over 4

=item * Purpose

Identify the name of the column in the incoming taxonomy which serves as the
path column.

=item * Arguments

    my $path_col = $self->path_col;

No arguments; the information is already inside the object.

=item * Return Value

String.

=item * Comment

Read-only.

=back

=cut

sub path_col {
    my $self = shift;
    return $self->{path_col};
}

=head2 C<path_col_sep()>

=over 4

=item * Purpose

Identify the string used to separate path components once the taxonomy has
been created.  This is just a "getter" and is logically distinct from the
option to C<new()> which is, in effect, a "setter."

=item * Arguments

    my $path_col_sep = $self->path_col_sep;

No arguments; the information is already inside the object.

=item * Return Value

String.

=item * Comment

Read-only.

=back

=cut

sub path_col_sep {
    my $self = shift;
    return $self->{path_col_sep};
}

sub get_all_child_counts {
    my $self = shift;
    return $self->{child_counts};
}

sub get_child_count {
    my ($self, $node) = @_;
    croak "Node '$node' not found" unless exists $self->{child_counts}{$node};
    return $self->{child_counts}{$node};
}

sub local_validate {
    my ($self, $args) = @_;

    croak "Argument to 'rules' element must be an array ref"
        unless defined $args and reftype($args->{rules}) eq 'ARRAY';
    foreach my $rule (@{$args}) {
        croak "Each element in 'rules' must be a code ref"
            unless reftype($rule) eq 'CODE';
    }
    return 1;
}

1;

# vim: formatoptions=crqot
