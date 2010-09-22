use inc::Module::Install;

name 'App-Syndicator';
abstract_from 'lib/App/Syndicator.pm';
version 0.001;
license 'perl';
perl_version '5.008';

requires 'MooseX::Declare' => 0;
requires 'MooseX::Types' => 0;
requires 'MooseX::Types::URI' => 0;
requires 'MooseX::Types::DateTime' => 0;
requires 'MooseX::Getopt' => 0;
requires 'MooseX::ConfigFromFile' => 0;
requires 'Config::Any' => 0;
requires 'JSON::Any' => 0;
requires 'HTML::FormatText' => 0;
requires 'Curses::UI' => 0;
requires 'XML::Feed::Aggregator' => 0.03;
requires 'KiokuDB' => 0;
requires 'DateTime' => 0;
requires 'Digest::MD5' => 0;
requires 'DBD::SQLite' => 0;
requires 'IO::All' => 0;

test_requires 'Test::NoWarnings' => 0;
test_requires 'Test::More' => 0;

install_script "syndicator";
tests "t/*.t";

WriteAll;
