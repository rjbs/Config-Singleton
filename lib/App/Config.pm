package App::Config;

use warnings;
use strict;

use Cwd ();
use File::Basename ();
use File::HomeDir ();
use File::Spec ();
use YAML::Syck ();

use Sub::Exporter -setup => {
  groups => [ setup => \'_build_config_methods' ],
};

=head1 NAME

App::Config - Easy configuration base class for your App.

=head1 VERSION

version 0.001

=cut

our $VERSION = '0.001';

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

=head1 DESCRIPTION

App::Config provides a base class for access to configuration data for your
app. The basic implementation stores its configuration in YAML in a text
file found in all the usual places. By default, App::Config looks for
myapp.yml, but an alternate filename may be passed when using the module.

This module was derived from L<Rubric::Config|Rubric::Config>.

=head1 USING APP::CONFIG

The L</SYNOPSIS> section, above, demonstrates an example of almost every
feature of App::Config.  It's a very simple module with a very small interface.

It is not a base class.  It is a utility for setting up a class that stores
loaded configuration data.  You just need to C<use> the module like this:

  package Your::Config;

  use App::Config -setup => {
    filename => 'your_program.yaml',
    template => {
      username => undef,
      hostname => undef,
      logfile  => undef,
      facility => 'local1',
      path     => [ qw(/var/spool /tmp/jobs) ],
    },
  };

When another module uses Your::Config, F<your_program.yaml> will be loaded and
its contents will be merged over the defaults given by the C<template>
argument.  Each entry in the template hashref becomes a method on
YourProgram::Config, which returns either the value from the config file or the
value from the template, if no entry exists in the config file.

So, assuming that F<your_program.yaml> looks like this:

  ---
  username: rjbs
  hostname: fulfill.example.com

  path:
    - /var/spool/jobs
    - /home/rjbs/spool/jobs

Then these are the results of method calls on Your::Config:

  Your::Config->username; # 'rjbs'

  Your::Config->logfile;  # undef

  Your::Config->facility; # 'local0'

  Your::Config->path;     # qw(/var/spool/jobs  /home/rjbs/spool/jobs)

The configuration file is found by looking for the given name in the following
paths (LOC is the location of the program being run, found in C<$0>):

  ./
  ../
  LOC/
  LOC/../etc/
  ~/
  /usr/local/etc/
  /etc/

You can change the paths checked by providing a F<path> argument in the setup
arguments.

If you'd rather look for a different filename, you can specify it when using
Your::Config:

  use Your::Config 'alt.yaml';

When Your::Config is loaded in this way, it will look for the given filename
instead of the default one.  If it is loaded again with a different filename
given, an exception will be raised.

=head1 METHODS

App::Config doesn't actually have any real public methods of its own.  Its
methods are all private, and serve to power its C<import> routine.  These will
probably be exposed in the future to allow for subclassing of App::Config, but
in the meantime, don't rely on them.

=cut

# Initialize all the methods for our new class.
# this is a Sub::Exporter group generator
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

  # XXX: implement default obj -- rjbs, 2007-08-18
  my $default;
  $sub{_self} = sub {
    return $_[0] if ref $_[0];
    return $default ||= (bless {} => shift);
  };

  for my $attr (keys %{ $arg->{template} }) {
    Carp::croak "can't use reserved name $attr as config entry"
      if exists $sub{ $attr };

    $sub{ $attr } = $self->_build_accessor($attr, $arg);
  }

  return \%sub;
}

# Build accessors for all of $template
sub _build_accessor {
  my ($class, $attr, $arg) = @_;

  return sub {
    my $self  = shift->_self;
    
    exists $self->config_from_file->{$attr}
         ? $self->config_from_file->{$attr}
         : $arg->{$attr}
  };
}

# Returns the method later referred to as config_filename.
#
# config_filename, deduces what the name of the config file it should look for
# will be.  Was it passed in, or should we guess based on the module name?
sub _build_config_filename {
  my ($class, $arg) = @_;

  sub {
    my ($self) = @_;
    my $class = ref $self ? ref $self : $self;
  
    unless ($arg->{filename}) {
      # remove final part (A::Config -> A)
      (my $module_base = $class) =~ s/::\w+\z//;

      $module_base =~ s/::/_/g;
      $arg->{filename} = $ENV{uc($module_base) . '_CONFIG_FILE'}
                      || lc($module_base) . '.yml';
    }

    return $arg->{filename};
  }
}

# Returns the method later referred to as config_from_file.
#
# config_from_file returns the config data, if loaded.  If it hasn't already
# been loaded, it finds and parses the configuration file, then returns the
# data.
sub _build_config_from_file {
  my ($app_config, $arg) = @_;
 
  return sub {
    my ($self) = shift->_self;
    return $self->{loaded_config} if $self->{loaded_config};
    
    my $config_filename = $app_config->_find_file_in_path(
      $self->config_filename,
      $arg->{path},
    );

    my $file_data = YAML::Syck::LoadFile($config_filename);
    my $config = $app_config->_merge_data($self->template, $file_data);

    return $self->{loaded_config} = $config;
  }
}

sub _build_import {
  my ($app_config, $arg) = @_;

  return sub {
    my ($class, $filename) = @_;

    Carp::confess sprintf("import called on %s object", ref $class)
      if ref $class;

    if ($filename and $filename =~ /^-/) {
      if ($filename eq '-client') {
        return if $class->_default_object;
        Carp::croak "$class not configured yet, but got -client directive";
      } else {
        Carp::croak "unknown directive for $class: $filename";
      }
    } elsif ($filename) {
      $class->_set_default_filename($filename);
    }

    $class->_self;
  }
}

sub _find_file_in_path {
  my ($self, $filename, $path) = @_;

  $path ||= $self->_default_path;

  for my $dir (@$path) {
    my $this_file = File::Spec->catfile($dir, $filename);
    return $this_file if -e $this_file;
  };

  Carp::croak "config file $filename not found in path (@$path)\n";
}

sub _default_path {
  my $home = File::HomeDir->my_home;
  my $path = File::Basename::dirname(Cwd::realpath($0));

  return [
    q{},
    q{./},
    q{../},
    qq{$path/},
    qq{$path/../etc/},
    qq{$home/.},
    q{/usr/local/etc/},
    q{/etc/},
  ];
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

=head1 AUTHOR

John Cappiello, C<< <jcap at cpan.org> >>

Ricardo SIGNES, C<< <rjbs at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Config>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Config

You can also look for information at:

=over 4

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Config>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Config>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Config>

=back

=head1 TODO

=over 4

=item * a ->new method to allow loading different configs

=item * a way to tell Your::Config, with no explicit filename, to die unless a filename was specified by an earlier use

=back

=head1 ACKNOWLEDGEMENTS

Ricardo SIGNES not only wrote the inspiration for this in Rubric::Config, but
he also basically wrote the majority of the implementation here, and even
provided extensions of what he knew I wanted it to do, even when I said I
didn't need that yet. In the end it ended up being extremely elegant, which I
can say without being boastful, because he wrote the elegant bits.

=head1 COPYRIGHT & LICENSE

Copyright 2006, John Cappiello.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
