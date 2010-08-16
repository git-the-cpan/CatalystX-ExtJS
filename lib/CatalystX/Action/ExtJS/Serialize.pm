#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2010 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::Action::ExtJS::Serialize;
BEGIN {
  $CatalystX::Action::ExtJS::Serialize::VERSION = '1.110000';
}
# ABSTRACT: Handle responses from uploads
use strict;
use warnings;

use base 'Catalyst::Action::Serialize';

sub execute {
    my ( $self, $controller, $c ) = @_;
    $self->next::method( $controller, $c );
    if ( $c->stash->{upload} ) {
        $c->res->content_type('text/html');
        my $body = $c->res->body;
        $body =~ s/&quot;/\&quot;/;
        $c->res->body(
            '<html><body><textarea>' . $body . '</textarea></body></html>' );
    }
}

1;



=pod

=head1 NAME

CatalystX::Action::ExtJS::Serialize - Handle responses from uploads

=head1 VERSION

version 1.110000

=head1 PUBLIC METHODS

=head2 execute

Wrap the serialized response in a textarea field if there was a file upload.
Furthermore set the C<content-type> to C<< text/html >>.

=cut

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

