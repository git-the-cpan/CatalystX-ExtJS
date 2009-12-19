
use strict;
use warnings;



use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'CatalystX-ExtJS',
  NAME      => 'CatalystX::ExtJS',
  AUTHOR    => "Moritz\ Onken\ \<onken\@netcubed\.de\>",
  ABSTRACT  => "Collection\ of\ modules\ for\ ExtJS",
  VERSION   => '0.10',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'bsd') : ()),
  PREREQ_PM    => {
    "Catalyst::View::TT" => '0',
    "Catalyst::Request::REST::ForBrowsers" => '0',
    "HTML::FormFu::Model::DBIC" => '0',
    "Catalyst::Action::RenderView" => '0',
    "Test::More" => '0.92',
    "Catalyst::Model::DBIC::Schema" => '0.29',
    "Lingua::EN::Inflect" => '0',
    "HTML::Entities" => '0',
    "Path::Class" => '0',
    "JSON" => '0',
    "Catalyst::Runtime" => '5.8',
    "HTML::FormFu::ExtJS" => '0.075',
    "Config::Any" => '0.17',
    "Test::WWW::Mechanize::Catalyst" => '0',
    "DBIx::Class" => '0',
  },
  test => {TESTS => 't/*.t t/rest/*.t'}
);

