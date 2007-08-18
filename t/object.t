#!perl -T

use Test::More tests => 6;

use lib 't/lib';

BEGIN {
	use_ok( 'MyApp::Config', 't/etc/mycustom.yml' );
}

is( MyApp::Config->hostname, 'localhost', 'Default config value expected');
 
is( MyApp::Config->username, 'faceman', 'Overriden config value expected');

my $config = MyApp::Config->new('etc/obj-1.yaml');

isa_ok($config, 'MyApp::Config');

is( $config->username, 'hm murdock', 'got username value from object');

is( MyApp::Config->username, 'faceman', 'but class method remains unchanged');
