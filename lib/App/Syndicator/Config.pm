package App::Syndicator::Config;
use MooseX::Declare;

role App::Syndicator::Config with MooseX::ConfigFromFile {
    use Data::Dumper;
    use Config::Any;
    use Try::Tiny;

    sub get_config_from_file {
        my ($self, $file) = @_;

        try {
            my $cfg = Config::Any->load_files({files => [$file], use_ext => 0});
            return $cfg->[0]->{config};
        }
        catch {
            die "couldn't load config from $file: $_";
        };
    }
}

1;
