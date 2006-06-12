package App::Config;

use warnings;
use strict;

use Data::Dump::Streamer;

use base qw(Class::Accessor);
use base qw(Class::Default);

use Cwd qw(realpath);
use File::Basename;
use File::HomeDir qw(home);
use YAML qw(LoadFile);


=head1 NAME

App::Config - Easy configuration base class for your App.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    package MyApp::Config;
    use base App::Config "myapp.yml";

    =head1 SETTINGS

    =over 4
    
    =item * hostname

    the hostname to connect to for MyApp

    =item * username

    the username to login with

    =item * charset

    the charset for MyApp
    
    =back 

    =cut

    my $template = {
      hostname => 'localhost',
      username => undef,
      charset  => 'ISO-8859-1',
    };

  Elsewhere...
    
    use MyApp::Config;
    
    MyApp->connect( MyApp::Config->localhost,
                    MyApp::Config->username );
  
    ...

=head1 DESCRIPTION

App::Config provides a base class for access to configuration data for your
app. The basic implementation stores its configuration in YAML in a text
file found in all the usual places. By default, App::Config looks for
myapp.yml, but an alternate filename may be passed when using the module.

This was initially Rubric::Config by RJBS C<< <rjbs at cpan.org> >>.

=cut

sub new { bless {}, $_[0] }

my $module_base = __PACKAGE__;
$module_base =~ s/::[^(::)]+//g;
my $config_filename = $ENV{uc($module_base) . '_CONFIG_FILE'} || lc($module_base) . '.yml';

sub import {
	my ($class) = shift;
  $class->mk_ro_accessors(keys %{$class->_template});
	$config_filename = shift if @_;
}

=head1 METHODS

These methods are used by the setting accessors, internally:

=head2 _load_config

This method returns the config data, if loaded.  If it hasn't already been
loaded, it finds and parses the configuration file, then returns the data.

=cut

sub _load_config {
  my $self = shift->_self;
  return $self if keys %{$self};

  die "You must define your configurable parameters in the _template sub"
    unless keys %{$self->_template};
 
  my $config_file;
  my $home = home;
  my $path = dirname(realpath($0));

  my @locations = ( "./",
                    "../",
                    "$path/",
                    "$path/../etc/",
                    "$home/.",
                    "/usr/local/etc/",
                    "/etc/",
                  );

  do {
    die "Config file not found: $config_filename" unless scalar(@locations);
    my $location = shift @locations;
    $config_file = $location . '/' . $config_filename;
    #warn $config_file . "\n";
  } until -e $config_file;

  $self = LoadFile($config_file);
}

=head2 _template

This method returns the template configuration as a hashref.

=cut

sub _template { 
  return {}
}

=head2 make_ro_accessor

App::Config isa Class::Accessor, and uses this sub to build its setting
accessors.  For a given field, it returns the value of that field in the
configuration, if it exists.  Otherwise, it returns the default for that field.

=cut

sub make_ro_accessor {
  my $self = shift->_self;
  my $field = shift;
	sub {
		exists $self->_load_config->{$field}
			? $self->_load_config->{$field}
			: $self->_template->{$field}
	}
}

=head1 AUTHOR

John Cappiello, C<< <jcap at cpan.org> >>
Ricardo SIGNES, C<< <rjbs at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-app-config at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Config>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Config

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Config>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Config>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Config>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Config>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 John Cappiello, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of App::Config
