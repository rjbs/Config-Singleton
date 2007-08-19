#!perl -T

use Test::More tests => 4;

use lib 't/lib';

require_ok('MyApp::Config');

eval { MyApp::Config->import(-client); };
like(
  $@,
  qr/not configured/,
  'importing with -client before anything else fails',
);

eval { MyApp::Config->import; };
is($@, '', 'but we can import with no filename, get the default...');

eval { MyApp::Config->import('-client'); };
is($@, '', '...and then -client works just fine');
