use inc::Module::Install;

name 'App-Syndicator';
abstract_from 'lib/App/Syndicator.pm';
version 0.003;
license 'perl';
perl_version '5.008';

requires 'MooseX::Declare' => 0.33;
requires 'MooseX::Types' => 0.23;
requires 'MooseX::Types::URI' => 0.02;
requires 'MooseX::Types::DateTime' => 0.05;
requires 'MooseX::Getopt' => 0.31;
requires 'MooseX::ConfigFromFile' => 0.02;
requires 'Config::Any' => 0.20;
requires 'JSON::Any' => 1.22;
requires 'HTML::FormatText' => 2.04;
requires 'Curses::UI' => 0.9607;
requires 'XML::Feed::Aggregator' => 0.03;
requires 'KiokuDB' => 0.49;
requires 'KiokuDB::Backend::DBI' => 1.15;
requires 'DateTime' => 0.61;
requires 'Digest::MD5' => 2.39;
requires 'DBD::SQLite' => 1.29;
requires 'Try::Tiny' => 0.06;
requires 'IO::All' => 0.41;

test_requires 'Test::More' => 0.94;
test_requires 'Test::UseAllModules' => 0.12;

install_script "syndicator";
tests "t/*.t";

WriteAll;
