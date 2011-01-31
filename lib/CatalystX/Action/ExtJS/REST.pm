#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::Action::ExtJS::REST;
BEGIN {
  $CatalystX::Action::ExtJS::REST::VERSION = '2.0.0';
}
# ABSTRACT: Mark an action as REST endpoint
use Moose;
extends 'Catalyst::Action';

1;



=pod

=head1 NAME

CatalystX::Action::ExtJS::REST - Mark an action as REST endpoint

=head1 VERSION

version 2.0.0

=head1 DESCRIPTION

The purpose of this action class is to mark an action as REST endpoint. 
Actions with this action will become a L<CatalystX::Controller::ExtJS::Direct::Route::REST> route.

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

