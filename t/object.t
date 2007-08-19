#!perl -T

use Test::More tests => 11;

use lib 't/lib';

BEGIN {
	use_ok( 'MyApp::Config', 't/etc/mycustom.yml' );
}

is( MyApp::Config->hostname, 'localhost', 'Default config value expected');
is( MyApp::Config->username, 'faceman', 'Overriden config value expected');

my $config = MyApp::Config->new('etc/obj-1.yaml');
isa_ok($config, 'MyApp::Config');
is($config->username, 'hm murdock', 'got username value from object');
is(MyApp::Config->username, 'faceman', 'but class method remains unchanged');

my $config_2 = MyApp::Config->new('etc/obj-2.yaml');
isa_ok($config_2, 'MyApp::Config');
is($config_2->username, 'ba baracus', 'got username value from object');
is(MyApp::Config->username, 'faceman', 'but class method remains unchanged');
is($config->username, 'hm murdock', 'so does the previous object');

# Honestly, why would you do this?
eval { $config->import };
like($@, qr/import called on.+object/, "import is a class method only");
