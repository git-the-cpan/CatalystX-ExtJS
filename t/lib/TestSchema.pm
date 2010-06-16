#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2010 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package
  TestSchema;
  
use strict;
use warnings;

use Path::Class::File;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


sub ddl_filename {
    return 't/sqlite.sql';
}

1;