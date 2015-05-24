package Parse::File::Taxonomy;
use strict;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.01';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

=head1 NAME

Parse::File::Taxonomy - Validate a file for use as a taxonomy

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

C<Parse::File::Taxonomy->new() should also be able to accept a reference to an
array of CSV records already held in memory.

TODO:  What would it mean for C<Parse::File::Taxonomy->new() to accept a
filehandle as an argument, rather than a file?  Would that be difficult to
implement?

The user of this library, however, must be permitted to write B<additional
validation rules> which will be applied to a taxonomy file provided as an
argument to the constructor.  Should the file fail to meet those rules, the
file will not be considered a valid taxonomy even if it meets the rules built
into the library itself.  Hence, C<Parse::File::Taxonomy->new()> must also be
able to accept a reference to an array of references to subroutines, each of
which subroutines must express one additional validation rule to be applied
sequentially.

=head2 The Parse::File::Taxonomy Object

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

That's better.  We have 13 elements in the hash, each corresponding to one of
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
        key_delim   => q{ - },
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

=cut

1;

# vim: formatoptions=crqot
