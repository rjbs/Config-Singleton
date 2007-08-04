package MyApp::Config;
use base App::Config;

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

sub _template {
  return { 
    hostname => 'localhost',
    username => undef,
    charset  => 'ISO-8859-1',
  };
};

1;
