#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Ruby::VersionManager' ) || print "Bail out!\n";
    use_ok( 'Ruby::VersionManager::Config' ) || print "Bail out!\n";
}

diag( "Testing Ruby::VersionManager $Ruby::VersionManager::VERSION, Perl $], $^X" );
