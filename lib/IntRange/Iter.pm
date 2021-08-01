package IntRange::Iter;

# AUTHORITY
# DATE
# DIST
# VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(intrange_iter);

# allow_dash
our $re1a = qr/\A(?:
                   (?:(?:-?[0-9]+)(?:\s*-\s*(?:-?[0-9]+))?)
                   (
                       \s*,\s*
                       (?:(?:-?[0-9]+)(?:\s*-\s*(?:-?[0-9]+))?)
                   )*
               )\z/x;
our $re1b = qr/\A
               (?:\s*,\s*)?(?:
                   (-?[0-9]+)\s*-\s*(-?[0-9]+) | (-?[0-9]+)
               )
              /x;

# allow_dotdot
our $re2a = qr/\A(?:
                   (?:(?:-?[0-9]+)(?:\s*\.\.\s*(?:-?[0-9]+))?)
                   (
                       \s*,\s*
                       (?:(?:-?[0-9]+)(?:\s*\.\.\s*(?:-?[0-9]+))?)
                   )*
               )\z/x;
our $re2b = qr/\A
               (?:\s*,\s*)?(?:
                   (-?[0-9]+)\s*\.\.\s*(-?[0-9]+) | (-?[0-9]+)
               )
              /x;

# allow_dash + allow dotdot
our $re3a = qr/\A(?:
                   (?:(?:-?[0-9]+)(?:\s*(?:-|\.\.)\s*(?:-?[0-9]+))?)
                   (
                       \s*,\s*
                       (?:(?:-?[0-9]+)(?:\s*(?:-|\.\.)\s*(?:-?[0-9]+))?)
                   )*
               )\z/x;
our $re3b = qr/\A
               (?:\s*,\s*)?(?:
                   (-?[0-9]+)\s*(?:-|\.\.)\s*(-?[0-9]+) | (-?[0-9]+)
               )
              /x;

sub intrange_iter {
    my $opts = ref($_[0]) eq 'HASH' ? shift : {};
    my $intrange = shift;

    my $allow_dash   = $opts->{allow_dash} // 1;
    my $allow_dotdot = $opts->{allow_dotdot} // 0;
    unless ($allow_dash || $allow_dotdot) { die "At least must enable allow_dash or allow_dotdot" }

    my ($re_a, $re_b);
    if ($allow_dash && $allow_dotdot) { ($re_a, $re_b) = ($re3a, $re3b) }
    elsif ($allow_dash)               { ($re_a, $re_b) = ($re1a, $re1b) }
    elsif ($allow_dotdot)             { ($re_a, $re_b) = ($re2a, $re2b) }

    unless ($intrange =~ $re_a) {
        die "Invalid syntax for intrange, please use a (1), a-b (1-3), or sequence of a-b (1,5-10,15)";
    }

    my @subranges;
    while ($intrange =~ s/$re_b//) {
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

  my $iter = intrange_iter('1,5-10,15-17'); # or: intrange_iter({allow_dotdot=>1}, '1,5-10,15..17');

  while (my $val = $iter->()) { ... } # 1, 5,6,7,8,9,10, 15,16,17 undef, ...


=head1 DESCRIPTION

This module provides a simple (coderef) iterator which you can call repeatedly
to get numbers specified in an integer range specification (string). When the
numbers are exhausted, the coderef will return undef. No class/object involved.


=head1 FUNCTIONS

=head2 intrange_iter

Usage:

 $iter = intrange_iter([ \%opts ], $spec); # coderef

Options:

=over

=item * allow_dash

Bool. Default true. At least one of C<allow_dash> or L</allow_dotdot> must be
true.

=item * allow_dotdot

Bool. Default false. At least one of L</allow_dash> or C<allow_dotdot> must be
true.

=back


=head1 SEE ALSO

Other iterators: L<Range::Iter>, L<NumSeq::Iter>.

CLI for this module: L<seq-intrange> (from L<App::seq::intrange>)

L<Regexp::Pattern::IntRange>

L<Sah::Schemas::IntRange>

Modules that might also interest you: L<Set::IntSpan> and L<Array::IntSpan>.

=cut
