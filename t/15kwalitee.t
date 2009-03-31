#!/usr/bin/perl

# @(#)$Id: 15kwalitee.t 90 2009-01-26 16:55:34Z pjf $

use strict;
use warnings;
use Test::More;

use version; our $VERSION = qv( sprintf '0.2.%d', q$Rev: 90 $ =~ /\d+/gmx );

BEGIN {
   if ($ENV{AUTOMATED_TESTING} || $ENV{PERL_CR_SMOKER_CURRENT}
       || ($ENV{PERL5OPT} || q()) =~ m{ CPAN-Reporter }mx
       || ($ENV{PERL5_CPANPLUS_IS_RUNNING} && $ENV{PERL5_CPAN_IS_RUNNING})) {
      plan skip_all => q(CPAN Testing stopped);
   }
}

eval { require Test::Kwalitee; Test::Kwalitee->import() };

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if ($@);
