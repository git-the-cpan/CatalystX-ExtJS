#!perl
#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2010 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);

eval "use Test::Perl::Critic";
plan skip_all => 'Test::Perl::Critic required to criticise code' if $@;
all_critic_ok();
