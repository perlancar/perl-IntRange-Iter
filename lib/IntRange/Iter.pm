package IntRange::Iter;

# AUTHORITY
# DATE
# DIST
# VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(intrange_iter);

sub intrange_iter {
    my $intrange = shift;

    unless ($intrange =~ /\A(?:
                              (?:(?:-?[0-9]+)(?:\s*(?:-|\.\.)\s*(?:-?[0-9]+))?)
                              (
                                  \s*,\s*
                                  (?:(?:-?[0-9]+)(?:\s*(?:-|\.\.)\s*(?:-?[0-9]+))?)
                              )*
                          )\z/x) {
        die "Invalid syntax for intrange, please use a (1), a-b (1-3), a..b (1..3) or sequence of a-b (1,5-10,15)";
    }

    my @subranges;
    while ($intrange =~ s/\A
                         (?:\s*,\s*)?(?:
                             (-?[0-9]+)\s*(?:-|\.\.)\s*(-?[0-9]+) | (-?[0-9]+)
                         )
                        //x) {
        push @subranges, defined($1) ? [$1, $2] : $3;
    }
    #use DD; dd \@subranges;
    my $cur_subrange = 0;
    my ($m, $n);
    return sub {
      RESTART:
        return undef if $cur_subrange > $#subranges;
        if (ref $subranges[$cur_subrange] eq 'ARRAY') {
            unless (defined $m) {
                ($m, $n) = (@{ $subranges[$cur_subrange] });
            }
            if ($m > $n) {
                $cur_subrange++;
                undef $m; undef $n;
                goto RESTART;
            } else {
                return $m++;
            }
        } else {
            return $subranges[$cur_subrange++];
        }
    };
}

1;
#ABSTRACT: Generate a coderef iterator from an int range specification (e.g. '1,5-10,20')

=for Pod::Coverage .+

=head1 SYNOPSIS

  use IntRange::Iter qw(intrange_iter);

  my $iter = intrange_iter('1,5-10,15'); # or: 1,5..10,15
  while (my $val = $iter->()) { ... } # 1, 5,6,7,8,9,10, 15, undef, ...


=head1 DESCRIPTION

This module provides a simple (coderef) iterator which you can call repeatedly
to get numbers specified in an integer range specification (string). When the
numbers are exhausted, the coderef will return undef. No class/object involved.


=head1 FUNCTIONS

=head2 intrange_iter


=head1 SEE ALSO

L<Range::Iter>

=cut
