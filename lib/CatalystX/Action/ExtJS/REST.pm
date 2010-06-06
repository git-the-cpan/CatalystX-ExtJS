# 
# This file is part of CatalystX-ExtJS
# 
# This software is Copyright (c) 2010 by Moritz Onken.
# 
# This is free software, licensed under:
# 
#   The (three-clause) BSD License
# 
package CatalystX::Action::ExtJS::REST;
BEGIN {
  $CatalystX::Action::ExtJS::REST::VERSION = '1.101570';
}
# ABSTRACT: Construct a new request class
use Moose;
extends 'Catalyst::Action';

use Catalyst::Utils;
use Carp;

my @traits = qw(Catalyst::TraitFor::Request::REST CatalystX::TraitFor::Request::ExtJS);

# not sure if this is the best place to mess with the request class

sub new {
    my $class    = shift;
    my ($config) = @_;
    my $app      = Catalyst::Utils::class2appclass( $config->{class} );
    unless ( $app && $app->can('request_class') ) {
        croak q(Couldn't set the request class. Use REST::ExtJS from your application classes only!);
    }

    my $req_class = $app->request_class;
    
    return $class->next::method(@_) if $req_class->can('is_ext_upload');

    my $meta = $req_class->meta->create_anon_class(
        superclasses => [$req_class],
        roles        => [@traits],
        cache        => 1
    );
    $meta->make_immutable;
    $app->request_class( $meta->name );
    return $class->next::method(@_);
}

1;

__END__
=pod

=head1 NAME

CatalystX::Action::ExtJS::REST - Construct a new request class

=head1 VERSION

version 1.101570

=head1 AUTHOR

  Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

