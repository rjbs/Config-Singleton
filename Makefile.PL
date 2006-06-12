#!perl

use strict;
use warnings;
use inc::Module::Install;

author 'John Cappiello <jcap@cpan.org>';
name 'App-Config';
all_from;

build_requires 'Test::More' => 0;

requires 'Class::Accessor' => 0;
requires 'Class::Default' => 0;
requires 'File::HomeDir' => 0;
requires 'YAML' => 0;

auto_install;
WriteAll;
