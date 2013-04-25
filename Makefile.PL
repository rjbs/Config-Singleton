#!perl
use strict;
use warnings;
use inc::Module::Install;

author   'John Cappiello <jcap@cpan.org>';
name     'Config-Singleton';
all_from 'lib/Config/Singleton.pm';

build_requires 'Test::More' => 0;

requires 'Cwd'            => 0; # core since 5
requires 'File::Basename' => 0; # core since 5
requires 'File::HomeDir'  => 0.60;  # the "modern" interface
requires 'File::Spec'     => 0; # core since 5.00405
requires 'Sub::Exporter'  => 0.972; # for name-ref for generator
requires 'YAML::Syck'     => 0; # minimum unknown

author_tests 'xt';

WriteAll;
