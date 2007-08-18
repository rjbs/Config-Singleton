#!perl -T

use Test::More tests => 4;

use lib 't/lib';

require_ok('MyApp::Config');

eval { MyApp::Config->import('etc/custom.yaml'); };
is($@, '', 'we can import MyApp::Config once (with a filename)');

eval { MyApp::Config->import('etc/custom.yaml'); };
is($@, '', 'we can import MyApp::Config again (with the same filename)');

eval { MyApp::Config->import; };
like($@, qr/already/, '...but we die on an attempt with a no filename');
