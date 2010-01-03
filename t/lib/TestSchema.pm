package
  TestSchema;
our $VERSION = '0.11';
  
use strict;
use warnings;

use Path::Class::File;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


sub ddl_filename {
    return 't/sqlite.sql';
}

1;