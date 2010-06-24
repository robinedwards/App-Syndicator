use strict;
use warnings;
use Test::More qw/no_plan/;
BEGIN { use_ok('App::Syndicator') };

App::Syndicator->new_with_options->run;

ok(1,'didnt die');
