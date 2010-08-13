use MooseX::Declare;

role App::Syndicator::Config with MooseX::ConfigFromFile {
    use MooseX::Types::Moose qw/ClassName Str/;
    use App::Syndicator::Types qw/File/;
    use Config::Any;
    use Try::Tiny;

    method get_config_from_file (ClassName $class: File $file ) {
        die "config file $file is not a file!" unless -f $file;

        try {
            my $cfg = Config::Any->load_files({files => [$file], use_ext => 0});
            return $cfg->[0]->{config};
        }
        catch {
            die "Couldn't load config from $file: $_";
        };
    }
}

1;
