# @(#)$Id: 05kwalitee.t 164 2010-12-18 18:19:08Z pjf $

use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.6.%d', q$Rev: 164 $ =~ /\d+/gmx );
use File::Spec::Functions;
use FindBin qw( $Bin );
use lib catdir( $Bin, updir, q(lib) );

use English qw( -no_match_vars );
use Test::More;

if (!-e catfile( $Bin, updir, q(MANIFEST.SKIP) )) {
   plan skip_all => 'Kwalitee test only for developers';
}

eval { require Test::Kwalitee; };

plan skip_all => 'Test::Kwalitee not installed' if ($EVAL_ERROR);

Test::Kwalitee->import();

# Local Variables:
# mode: perl
# tab-width: 3
# End: