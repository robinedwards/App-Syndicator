use strict;
use warnings;
use Test::More tests => 1;
BEGIN { use_ok('App::Syndicator') };

App::Syndicator->new_with_options(configfile=>'cfg.json')->run;
