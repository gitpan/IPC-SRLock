# @(#)$Ident: Build.PL 2013-08-14 09:38 pjf ;

use strict;
use warnings;

use Module::Build;

sub whimper { print {*STDOUT} $_[ 0 ]."\n"; exit 0 }

$] >= 5.010001 or whimper 'Minimum required Perl version is 5.010001';

my $code = do { local $/; <DATA> };

Module::Build->subclass( code => $code )->new(
  'module_name' => 'IPC::SRLock',
  'notes'       => { min_perl_version => 5.010001 },
  'build_requires' => {
    'File::DataClass' => 'v0.22.0',
    'Module::Build' => '0.4004',
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
    'File::DataClass' => 'v0.22.0',
    'IPC::ShareLite' => '0.17',
    'Moo' => '1.003',
    'Time::Elapsed' => '0.29',
    'Try::Tiny' => '0.09',
    'Type::Tiny' => '0.012',
    'Unexpected' => 'v0.6.0',
    'namespace::sweep' => '0.006'
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
