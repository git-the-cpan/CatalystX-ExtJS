
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Catalyst' => '0',
    'Catalyst::Engine::HTTP' => '0',
    'Catalyst::Model::DBIC::Schema' => '0',
    'Catalyst::Request::REST::ForBrowsers' => '0',
    'Catalyst::View::JSON' => '0',
    'Catalyst::View::TT' => '0',
    'DBIx::Class' => '0',
    'DBIx::Class::ResultSet' => '0',
    'DBIx::Class::Schema' => '0',
    'English' => '0',
    'File::Find' => '0',
    'File::Spec' => '0',
    'File::Temp' => '0',
    'FindBin' => '0',
    'Getopt::Long' => '0',
    'HTTP::Request::Common' => '0',
    'JSON' => '0',
    'Module::Build' => '0.3601',
    'Path::Class::File' => '0',
    'Pod::Usage' => '0',
    'Test::More' => '0.94',
    'Test::WWW::Mechanize::Catalyst' => '0',
    'perl' => '5.004'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Collection of modules for ExtJS',
  'dist_author' => [
    'Moritz Onken <onken@netcubed.de>'
  ],
  'dist_name' => 'CatalystX-ExtJS',
  'dist_version' => '1.123000',
  'license' => 'bsd',
  'module_name' => 'CatalystX::ExtJS',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Carp' => '0',
    'Catalyst::Action' => '0',
    'Catalyst::Action::Deserialize' => '0',
    'Catalyst::Action::REST' => '0.83',
    'Catalyst::Action::RenderView' => '0',
    'Catalyst::Action::Serialize' => '0',
    'Catalyst::Controller' => '0',
    'Catalyst::Controller::REST' => '0',
    'Catalyst::Runtime' => '5.80024',
    'Catalyst::Utils' => '0',
    'Class::Accessor::Fast' => '0',
    'Config::Any' => '0',
    'DBIx::Class' => '0.08123',
    'HTML::Entities' => '0',
    'HTML::FormFu' => '0.08',
    'HTML::FormFu::ExtJS' => '0.076',
    'HTML::FormFu::Model::DBIC' => '0.08',
    'JSON::Any' => '0',
    'JSON::XS' => '0',
    'JavaScript::Dumper' => '0.011',
    'Lingua::EN::Inflect' => '0',
    'List::Util' => '0',
    'Moose' => '1.06',
    'Moose::Role' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'MooseX::MethodAttributes' => '0',
    'Path::Class' => '0',
    'Scalar::Util' => '0',
    'namespace::autoclean' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
