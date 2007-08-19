#!perl -T

use Test::More tests => 2;

use lib 't/lib';

require_ok('App::Config');

eval {
  package YourApp::Config;
  App::Config->import(-setup => {
    template => { import => undef },
  });
};

like(
  $@,
  qr/reserved/,
  "you can't have methods like 'new' or 'import' in template",
);
