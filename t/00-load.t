#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Ruby::VersionManager' ) || print "Bail out!\n";
    use_ok( 'Ruby::VersionManager::Config' ) || print "Bail out!\n";
}

