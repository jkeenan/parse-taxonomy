package Parse::File::Taxonomy;
use strict;
use Carp;
use Text::CSV;
use Scalar::Util qw( reftype );
our $VERSION = '0.02';
#use Data::Dump;

=head1 NAME

Parse::File::Taxonomy - Validate a file for use as a taxonomy

=head1 SYNOPSIS

    use Parse::File::Taxonomy;

=head1 DESCRIPTION

This module is the base class for the Parse-File-Taxonomy extension to the
Perl 5 programming language.  You will not instantiate objects of this class;
rather, you will instantiate objects of subclasses, of which
Parse::File::Taxonomy::Path will be the first.

B<This is an ALPHA release.>

=head2 Taxonomy: definition

For the purpose of this library, a B<taxonomy> is defined as a tree-like data
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

For the purpose of this module, a B<taxonomy file> is a CSV file in which (a)
certain columns hold data from which the position of each record within the
taxonomy can be derived; and (b) in which each node in the tree (other than
the root node) is uniquely represented by a record within the file.

=head3 CSV

B<"CSV">, strictly speaking, refers to B<comma-separated values>:

    path,nationality,gender,age,income,id_no

For the purpose of this module, however, the column separators in a taxonomy file
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
format.  In each non-header record in that file, there must be one or more
columns which hold data capable of exactly specifying the record's position in
the taxonomy, I<i.e.,> the route or B<path> from the root node to the node
being represented by that record.

The precise way in which certain columns are used to determine the path from
the root node to a given node is what differentiates various types of taxonomy
files from one another.  In Parse-File-Taxonomy we identify two different
flavors of taxonomy files and provide a class for the construction of each.

=head3 Taxonomy by path

A B<taxonomy by path> is one in which a single column -- which we will refer
to as the B<path column> -- will represent the path from the root to the given
record as a series of strings joined by separator characters.
Within that path column the value corresponding to the root node need
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

Then the taxonomy file describing the tree in Diagram 2 would look like this:

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

=head3 Taxonomy by index

A B<taxonomy by index> is one in which the data in which each record has a
column with a unique identifier (B<id>) and another column holding the
unique identifier (B<parent_id>) of the record representing the next higher node in the
hierarchy.  The record must also a column which holds a datum that is unique
among all records having the same parent node.

Let's make this clearer by rewriting the taxonomy-by-path above for Example 3
as a taxonomy-by-index.

    "id","parent_id","name","nationality","gender","age","income","id_no"
    1,,"Alpha","","","","",""
    2,1,"Epsilon","","","","",""
    3,2,"Kappa","","","","",""
    4,1,"Zeta","","","","",""
    5,4,"Lambda","","","","",""
    6,4,"Mu","","","","",""
    7,,"Beta","","","","",""
    8,7,"Eta","","","","",""
    9,7,"Theta","","","","",""
    10,,"Gamma","","","","",""
    11,10,"Iota","","","","",""
    12,11,"Delta","","","","",""
    13,,"Delta","","","","",""

In the above taxonomy-by-index, the records with C<id>s C<1>, C<7>, C<10>, and
C<13> are top-level nodes.   They have no parents, so the value of their
C<parent_id> column is null or, in Perl terms, an empty string.  The records
with C<id>s C<2> and C<4> are children of the record with C<id> of C<1>.  The
record with C<id 3> is, in turn, a child of the record with C<id 2>.

In the above taxonomy-by-index, close inspection will show that no two records
with the same C<parent_id> share the same C<name>.  The property of
B<uniqueness of sibling names> means that we can construct a non-indexed
version of the path from the root to a given node by using the C<parent_id>
column in a given record to look up the C<name> of the record with the C<id>
value identical to the child's C<parent_id>.

    Via index: 3        2       1

    Via name:  Kappa    Epsilon Alpha

We go from C<id 3> to its C<parent_id 2>, then to C<2>'s C<parent_id 1>.
Putting C<name>s to this, we go from C<Kappa> to C<Epsilon> to C<Alpha>.

Now, reverse the order of those C<name>s, throw a pipe delimiter before each
of them and join them into a single string, and you get:

    |Alpha|Epsilon|Kappa

... which is the value of the C<path> column in the third record in the
taxonomy-by-path displayed previously.

With correct data, a given hierarchy of data can therefore be represented
either by a taxonomy-by-path or by a taxonomy-by-index.  We would therefore
describe these two taxonomies as B<equivalent> to each other.

=head2 Taxonomy Validation

Each C<Parse::File::Taxonomy> subclass will have a constructor, C<new()>,
which will probe a taxonomy file
provided to it as an argument to determine whether it can be considered a
valid taxonomy according to the description provided above.  The arguments
needed for such a constructor will be found in the documentation of the
subclass.

TODO:  C<Parse::File::Taxonomy->new() should also be able to accept a
reference to an array of CSV records already held in memory.

TODO:  What would it mean for C<Parse::File::Taxonomy->new() to accept a
filehandle as an argument, rather than a file?  Would that be difficult to
implement?

TODO:  The user of this library, however, must be permitted to write
B<additional user-specified validation rules> which will be applied to a
taxonomy by means of a C<local_validate()> method called on a
Parse::File::Taxonomy object.  Should the file fail to meet those rules, the
user may choose not to proceed further even though the taxonomy meets the
basic validation criteria implemented in the constructor.  This method will
take a reference to an array of subroutines references as its argument.  Each
such code reference will be a user-defined rule which the taxonomy must obey.
The method will apply each code reference to the taxonomy in sequence and will
return with a true value if and only if all the individual criteria return
true as well.

=cut

sub fields {
    my $self = shift;
    return $self->{fields};
}

sub data_records {
    my $self = shift;
    return $self->{data_records};
}

1;

# vim: formatoptions=crqot
