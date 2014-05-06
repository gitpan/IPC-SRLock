use strict;
use warnings;

use Module::Build 0.4202;

sub whimper { print {*STDOUT} $_[ 0 ]."\n"; exit 0 }

my $perl_ver = 5.010001;
my $name     = 'IPC-SRLock'; $name =~ s{ - }{::}gmx;
my $prereqs  = {
  'build_requires' => {
    'File::DataClass' => 'v0.35.0',
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
    'File::DataClass' => 'v0.35.0',
    'IPC::ShareLite' => '0.17',
    'Moo' => '1.004002',
    'Time::Elapsed' => '0.29',
    'Try::Tiny' => '0.18',
    'Type::Tiny' => '0.030',
    'namespace::sweep' => '0.006',
    'perl' => '5.010001'
  },
};
my $osname   = lc $^O; ($osname eq 'mswin32' or $osname eq 'cygwin')
   and delete $prereqs->{requires}->{ 'IPC::ShareLite' };

if ($] < $perl_ver) {
   $ENV{AUTOMATED_TESTING}
      or $ENV{PERL_CPAN_REPORTER_CONFIG}
      or $ENV{PERL5_CPANPLUS_IS_VERSION}
      or whimper "Minimum required Perl version is ${perl_ver}";
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
