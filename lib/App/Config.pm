package App::Config;

use warnings;
use strict;

use Data::Dumper; # XXX temporary, presumably

use Cwd qw(realpath);
use File::Basename;
use File::HomeDir qw(home);
use YAML qw(LoadFile);

=head1 SYNOPSIS

  package YourApplication::Config;
  use App::Config -setup => {
    filename => 'something.yaml',
    template => {
      foo => undef,
      bar => 1024,
      qux => [ 1, 2, 3],
    },
  };

Elsewhere...

  use YourApplication::Config 'my_instance_config.yml';
  my $foo = YourApplication::Config->foo;

=cut 

use Sub::Exporter -setup => {
  groups     => [ setup => \'_build_config_methods' ],
};

# this is a group generator
sub _build_config_methods {
  my ($self, $name, $arg) = @_;

  # validate $arg here -- rjbs

  my %sub; # This is the set of subs we're going to install in config classes.

  $sub{config_filename}  = $self->_build_config_filename($arg);
  $sub{config_from_file} = $self->_build_config_from_file($arg);
  $sub{template}         = sub { $arg->{template} };

  # the import method generated will, I think, exist only to let you override 
  # the default filename
  $sub{import}           = $self->_build_import($arg);

  for my $attr (keys %{ $arg->{template} }) {
    # To avoid this condition, consider making internal methods ALL CAPS or 
    # something. -- rjbs
    Carp::croak "can't use reserved word $attr as config entry"
      if exists $sub{ $attr };

    $sub{ $attr } = $self->_build_accessor($attr, $arg);
  }

  return \%sub;
}

sub _build_accessor {
  my ($class, $attr, $arg) = @_;
  return sub {
    my $self  = shift;
    
  	exists $self->config_from_file->{$attr}
			? $self->config_from_file->{$attr}
			: $arg->{$attr}
  };
}

sub _build_config_filename {
  my ($class, $arg) = @_;

  sub {
    my ($class) = @_;
  
    unless ($arg->{filename}) {
      my $module_base =~ s/::\w+\z//; # remove final part (A::Config -> A)
      $module_base =~ s/::/_/g;
      $arg->{filename} = $ENV{uc($module_base) . '_CONFIG_FILE'}
                      || lc($module_base) . '.yml';
    }

    return $arg->{filename};
  }
}

# this is a generator, and needs to return a sub
sub _build_config_from_file {
  my ($app_config, $arg) = @_;
 
  my $config;
  return sub {
    return $config if $config;
    
    my $class = shift;
    die "You must define your configurable parameters in the template sub"
      unless keys %{$class->template};
 
    my $config_file;
    my $home = home;
    my $path = dirname(realpath($0));

    # TODO will make this configurable later
    my @locations = ( "./",
                      "../",
                      "$path/",
                      "$path/../etc/",
                      "$home/.",
                      "/usr/local/etc/",
                      "/etc/",
                    );

    my $config_filename = $class->config_filename; 
    do {
      die "Config file not found: $config_filename" unless scalar(@locations);
      my $location = shift @locations;
      $config_file = $location . $config_filename;
      #warn $config_file . "\n";
    } until -e $config_file;

    my $file_data = LoadFile($config_file);
    $config = $app_config->_merge_data($class->template, $file_data);
    return $config;
  }
}

# In the future, using Clone here might be a good idea to avoid
# issues with stupid references.
sub _merge_data {
  my ($self, $template, $override) = @_;
  

  my $merged = {};
  for (keys %$template) {
    $merged->{$_} = defined $override->{$_} ? $override->{$_} : $template->{$_};
  }
  
  return $merged;
}

sub _build_import {
  my ($app_config, $arg) = @_;
  return sub {
    my ($self, $filename) = @_;
    $arg->{filename} = $filename if $filename;
  }
}

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

=head1 METHODS

These methods are used by the setting accessors, internally:

=head2 _load_config

This method returns the config data, if loaded.  If it hasn't already been
loaded, it finds and parses the configuration file, then returns the data.

=cut
=head2 make_ro_accessor

App::Config isa Class::Accessor, and uses this sub to build its setting
accessors.  For a given field, it returns the value of that field in the
configuration, if it exists.  Otherwise, it returns the default for that field.

=cut
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
