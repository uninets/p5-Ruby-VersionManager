#!/usr/bin/perl

use 5.010;
use strict;
use feature 'say';
use warnings;

use Ruby::VersionManager;
use Getopt::Long;

my @valid_actions = qw| list install updatedb |;

my $action = shift;

die "No action '$action'" unless grep { $_ eq $action } @valid_actions;

my $ruby_version = '1.9';

GetOptions(
    'r|ruby=s' => \$ruby_version,
);

my $rvm = Ruby::VersionManager->new(
    ruby_version => $ruby_version,
);

if ($action ~~ 'list'){
    $rvm->list;
    exit 0;
}

if ($action ~~ 'updatedb'){
    $rvm->update_db;
    exit 0;
}

if ($action ~~ 'install'){
    $rvm->install;
}
