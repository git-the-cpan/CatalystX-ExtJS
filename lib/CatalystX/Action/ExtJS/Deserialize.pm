#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::Action::ExtJS::Deserialize;
BEGIN {
  $CatalystX::Action::ExtJS::Deserialize::VERSION = '1.124000';
}
# ABSTRACT: Skip deserialization for uploads
use strict;
use warnings;

use base 'Catalyst::Action::Deserialize';

sub execute {
    my ( $self, $controller, $c ) = @_;
    
    if (   $c->req->is_ext_upload )
    {
        unshift(@{$c->req->accepted_content_types}, 'application/json');
        return 1;
    }
    else {
        return $self->next::method( $controller, $c );
    }
}

1;



=pod

=head1 NAME

CatalystX::Action::ExtJS::Deserialize - Skip deserialization for uploads

=head1 VERSION

version 1.124000

=head1 PUBLIC METHODS

=head2 execute

Stops further deserialisation if the current request looks like a request
from ExtJS and has multipart form data, so usually an upload.

=cut

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

