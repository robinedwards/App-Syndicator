use MooseX::Declare;

class App::Syndicator with (App::Syndicator::Config, 
    MooseX::Getopt::Dashes) {
    use App::Syndicator::Importer;
    use MooseX::Types::Moose qw/Bool/;
    use App::Syndicator::Types ':all';

    our $VERSION = 0.001;

    has importer => (
        is => 'rw',
        isa => Importer_T,
        lazy_build => 1,
        required => 1,
    );

    has output => (
        is => 'ro',
        isa => Output_T,
        required => 1,
        default => 'curses',
    );

    has +configfile => (
        is => 'ro',
        required => 1,
        isa => File,
        default => "config",
    );

    has sources => (
        is => 'rw',
        required => 1,
        isa => UriArray,
        coerce => 1,
    );

    method BUILD {
        $self->importer(
            App::Syndicator::Importer->new(sources => $self->sources)
        );
    }

    method run { 
        my $output = $self->output;

        $self->can($output) 
            ? $self->$output
            : die "Unknown output type: $output";
    }

    method curses {
        require App::Syndicator::UI;

        my $ui = App::Syndicator::UI->new(
            entries => [$self->importer->retrieve],
            errors => [$self->importer->errors]
        );

        $ui->mainloop;
    }

    method console {
        require App::Syndicator::Output::Console;

        my $console = App::Syndicator::Output::Console->new(
            entries => [$self->importer->retrieve],
            errors => [$self->importer->errors]
        );
        
        $console->run;
    }
}


1;
__END__

=head1 NAME

App::Syndicator - Perl application for feed syndication

=head1 SYNOPSIS

 $ syndicator [--output=console] [--config=/your/config.any]

=head1 SEE ALSO

XML::Feed::Aggregator

=head1 AUTHOR

Rob Edwards, E<lt>rge@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Rob Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
