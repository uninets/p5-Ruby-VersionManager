#!/usr/bin/perl

use 5.010;
use strict;
use feature 'say';
use warnings;

use Ruby::VersionManager;
use Getopt::Long;

my @valid_actions = qw| list install updatedb |;

my $action = shift;
my $arg = shift;

die "No action '$action'" unless grep { $_ eq $action } @valid_actions;

my $rvm = Ruby::VersionManager->new();

if ($action ~~ 'list'){
    $rvm->list;
    exit 0;
}

if ($action ~~ 'updatedb'){
    $rvm->update_db;
    exit 0;
}

if ($action ~~ 'install'){
    my $ruby_version = $arg || '1.9';
    $rvm->ruby_version($ruby_version);
    $rvm->install;
}
