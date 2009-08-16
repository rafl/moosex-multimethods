use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    eval 'use MooseX::Declare (); use Test::NoWarnings;';
    plan skip_all => 'MooseX::Declare and Test::NoWarnings required'
        if $@;
}

use FindBin;
use lib "$FindBin::Bin/lib";

use_ok('MXD');
