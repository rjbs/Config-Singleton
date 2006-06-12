#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'App::Config' );
}

diag( "Testing App::Config $App::Config::VERSION, Perl $], $^X" );
