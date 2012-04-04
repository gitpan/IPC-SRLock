# @(#)$Id: CPANTesting.pm 186 2012-04-03 11:26:33Z pjf $

package CPANTesting;

use strict;
use warnings;

my $uname = qx(uname -a);

sub broken_toolchain {
   $ENV{PATH} =~ m{ \A /home/sand }mx and return 'Stopped Konig';
   $uname     =~ m{ higgsboson    }mx and return 'Stopped dcollins';
   return 0;
}

sub exceptions {
   $uname =~ m{ slack64 }mx and return 'Stopped bingos';
   return 0;
}

1;

__END__
