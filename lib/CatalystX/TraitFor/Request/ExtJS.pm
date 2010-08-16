#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2010 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::TraitFor::Request::ExtJS;
BEGIN {
  $CatalystX::TraitFor::Request::ExtJS::VERSION = '1.110000';
}
# ABSTRACT: Sets the request method via a query parameter
use Moose::Role;

use namespace::autoclean;
use JSON::XS;

has 'is_ext_upload' => ( isa => 'Bool', is => 'rw', lazy_build => 1 );

sub _build_is_ext_upload {
    my ($self) = @_;
    return $self->header('Content-Type')
      && $self->header('Content-Type') =~ /^multipart\/form-data/;
}

around 'method' => sub {
    my ( $orig, $self, $method ) = @_;
    return $self->$orig($method) if($method);
    return $self->query_params->{'x-tunneled-method'} || $self->$orig();
    

};

1;



=pod

=head1 NAME

CatalystX::TraitFor::Request::ExtJS - Sets the request method via a query parameter

=head1 VERSION

version 1.110000

=head1 METHODS

=head2 is_extjs_upload

Returns true if the current request looks like a request from ExtJS and has
multipart form data, so usually an upload. 

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

