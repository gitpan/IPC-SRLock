# @(#)$Ident: Build.PL 2013-09-02 14:56 pjf ;

use strict;
use warnings;

use Module::Build 0.4004;

sub whimper { print {*STDOUT} $_[ 0 ]."\n"; exit 0 }

my $perl_ver = 5.010001;
my $name     = 'IPC-SRLock'; $name =~ s{ - }{::}gmx;

$] >= $perl_ver or $ENV{PERL5_CPANPLUS_IS_VERSION}
   or whimper "Minimum required Perl version is ${perl_ver}";

Module::Build->subclass( code => do { local $/; <DATA> } )->new(
  'module_name' => $name,
  'notes'       => { min_perl_version => $perl_ver },
  'build_requires' => {
    'File::DataClass' => 'v0.22.0',
    'Module::Build' => '0.4004',
    'Test::Requires' => '0.06',
    'version' => '0.88'
  },
  'configure_requires' => {
    'Module::Build' => '0.4004',
    'version' => '0.88'
  },
  'recommends' => {
    'Cache::Memcached' => '1.24'
  },
  'requires' => {
    'Class::Null' => '1.09',
    'Date::Format' => '2.24',
    'File::DataClass' => 'v0.25.0',
    'IPC::ShareLite' => '0.17',
    'Moo' => '1.003',
    'Time::Elapsed' => '0.29',
    'Try::Tiny' => '0.09',
    'Type::Tiny' => '0.012',
    'Unexpected' => 'v0.12.0',
    'namespace::sweep' => '0.006',
    'perl' => '5.010001'
  },

)->create_build_script;

exit 0;

__DATA__

sub _normalize_prereqs { # Dynamic config
   my $self = shift; my $p = $self->SUPER::_normalize_prereqs;

   my $osname = lc $^O; ($osname eq 'mswin32' or $osname eq 'cygwin')
      and delete $p->{requires}->{ 'IPC::ShareLite' };

   return $p;
}
