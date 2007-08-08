#!perl -T

use Test::More tests => 3;

use lib 't/lib';

BEGIN {
	use_ok( 'MyApp::Config', 't/etc/my_custom.yml' );
}

is( MyApp::Config->hostname, 'localhost', 'Default config value expected');
 
is( MyApp::Config->username, 'faceman', 'Overriden config value expected');

