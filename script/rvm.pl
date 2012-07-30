#!/usr/bin/perl

use 5.010;
use strict;
use feature 'say';
use warnings;

use Ruby::VersionManager;
use Getopt::Long qw(:config pass_through);

my $action  = shift;
my $arg     = shift;
my @options = @ARGV;

die "No action defined." unless $action;

my $rvm = Ruby::VersionManager->new();

my $dispatch_table = {
    list => sub {
        $rvm->list;
        exit 0;
    },
    updatedb => sub {
        $rvm->updatedb;
        exit 0;
    },
    reinstall_gems => sub {
        $rvm->gem( 'reinstall', @options );
    },
    install => sub {
        my $ruby_version = $arg || '1.9';
        $rvm->ruby_version($ruby_version);
        $rvm->install;
    },
    uninstall => sub {
        my $ruby_version = $arg;
        die "no version defined" unless $ruby_version;

        $rvm->ruby_version($ruby_version);
        $rvm->uninstall;
    },
    version => sub {
        say Ruby::VersionManager::Version->get;
        exit 0;
    },
};

if ( exists $dispatch_table->{$action} ) {
    $dispatch_table->{$action}->();
}
else {
    say "No action $action defined";
}

__END__

=head1 NAME

rvm.pl

=head1 WARNING!

This is an unstable development release not ready for production!

=head1 VERSION

Version 0.003011

=head1 SYNOPSIS

rvm.pl will provide a subset of the bash rvm.

=head1 INSTALL RUBY

It is recommended to use Ruby::VersionManager with local::lib to avoid interference with possibly installed system ruby.
Ruby::VersionManager comes with a script rvm.pl with following options.

=head2 version

Show the version of Ruby::VersionManager.

    rvm.pl version

=head2 list

List available ruby versions.

    rvm.pl list

=head2 updatedb

Update database of available ruby versions.

    rvm.pl updatedb

=head2 install

Install a ruby version. If no version is given the latest stable release will be installed.
The program tries to guess the correct version from the provided string. It should at least match the major release.
If you need to install a preview or rc version you will have to provide the full exact version.

Latest ruby

    rvm.pl install

Latest ruby-1.8

    rvm.pl install 1.8

Install preview

    rvm.pl install ruby-1.9.3-preview1

To use the Ruby::VersionManager source ruby_vmanager.rc.

    source ~/.ruby_vmanager/var/ruby_vmanager.rc

=head2 uninstall

Remove a ruby version and the source dir including the downloaded archive.
You have to provide the full exact version of the ruby you want to remove as shown with list.

    rvm.pl uninstall ruby-1.9.3-preview1

If you uninstall your currently active ruby version you have to install/activate another version manually.

=head2 reinstall_gems

Reinstalls all gems listed in the given file. When no file is given at the command line the output of 'gem list' is used to determine which gems to reinstall.
The file has to be in the same format as the output of 'gem list'.
This action is not intended to repair any gem installation but to install identical gemsets on multiple machines. Missing dependencies will not be fixed.

    rvm.pl reinstall_gems gem_list.txt # installs all gems in the list ignoring dependencies

    rvm.pl reinstall_gems # reinstalls all installed gems

=head1 LIMITATIONS AND TODO

Currently Ruby::VersionManager is only running on Linux with bash installed.
Better support of gemsets needs to be added.

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

