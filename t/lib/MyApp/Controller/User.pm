package
  MyApp::Controller::User;
our $VERSION = '0.11';
  
use base 'CatalystX::Controller::ExtJS::REST';

__PACKAGE__->config(
    form_base_path => [qw(t root forms)],
    list_base_path => [qw(t root lists)],
);

sub add_to_group : Chained('base') Args(1) {
    
}


1;