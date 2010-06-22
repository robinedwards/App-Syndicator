package App::Syndicator::Config;
use MooseX::Declare;

role App::Syndicator::Config with MooseX::ConfigFromFile {
    use Config::Any;
    use Data::Dumper;

    sub get_config_from_file {
        my ($self, $file) = @_;

        my $cfg = Config::Any->load_files({files => [$file]});

        warn Dumper $cfg;

        return $cfg;
    } 
}

1;
