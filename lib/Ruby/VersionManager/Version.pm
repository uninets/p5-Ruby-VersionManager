package Ruby::VersionManager::Version;

use strict;
use warnings;
use version;

sub new {
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}

sub get {
    my $self = shift;
    my $VERSION = version->declare('0.03.08')->numify;
    return $VERSION;
}

1;

__END__

=head1 NAME

Ruby::VersionManager::Version

=head1 WARNING!

This is an unstable development release not ready for production!

=head1 VERSION

Version 0.003008

=head1 SYNOPSIS

Ruby::VersionManager::Version is uses to declare the Ruby::VersionManager version.

=head1 METHODS

=head2 new

    my $rvmv = Ruby::VersionManager::Version->new;

=head2 get

Used to get the current version of Ruby::VersionManager

    my $version = $rvmv->get;

Or

    my $version = Ruby::VersionManager::Version->get;

=head1 AUTHOR

Mugen Kenichi, C<< <mugen.kenichi at uninets.eu> >>

=head1 BUGS

Report bugs at:

=over 2

=item * Ruby::VersionManager issue tracker

L<https://github.com/mugenken/p5-Ruby-VersionManager/issues>

=item * support at uninets.eu

C<< <mugen.kenichi at uninets.eu> >>

=back

=head1 SUPPORT

=over 2

=item * Technical support

C<< <mugen.kenichi at uninets.eu> >>

=back

=cut

