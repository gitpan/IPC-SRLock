use strict;
use warnings;

use Module::Build 0.4202;

sub testing { $ENV{AUTOMATED_TESTING} || $ENV{PERL_CPAN_REPORTER_CONFIG}
                                      || $ENV{PERL5_CPANPLUS_IS_VERSION} }
sub whimper { print {*STDOUT} $_[ 0 ]."\n"; exit 0 }

my $perl_ver = 5.010001;
my $name     = 'IPC-SRLock'; $name =~ s{ - }{::}gmx;
my $prereqs  = {
  'build_requires' => {
    'File::DataClass' => 'v0.52.0',
    'Module::Build' => '0.4202',
    'Test::Requires' => '0.06',
    'version' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.4202',
    'version' => '0.88'
  },
  'recommends' => {
    'Cache::Memcached' => '1.24'
  },
  'requires' => {
    'Class::Null' => '1.09',
    'Date::Format' => '2.24',
    'File::DataClass' => 'v0.52.0',
    'IPC::ShareLite' => '0.17',
    'Moo' => '1.006000',
    'Time::Elapsed' => '0.31',
    'Try::Tiny' => '0.22',
    'Type::Tiny' => '1.000002',
    'namespace::autoclean' => '0.19',
    'perl' => '5.010001'
  },
};
my $osname   = lc $^O; ($osname eq 'mswin32' or $osname eq 'cygwin')
   and delete $prereqs->{requires}->{ 'IPC::ShareLite' };

if ($] < $perl_ver) { # Not interested in reports below min perl ver
   testing or whimper "Minimum required Perl version is ${perl_ver}";
   $prereqs->{build_requires} = { %{ $prereqs->{configure_requires} } };
   $prereqs->{build_requires}->{ 'Test::Requires' } = 0.06;
   delete $prereqs->{requires};
}

Module::Build->new(
  'module_name' => $name,
  'notes'       => { min_perl_version => $perl_ver },
  %{ $prereqs },

)->create_build_script;

exit 0;
