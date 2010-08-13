use MooseX::Declare;

class App::Syndicator with (App::Syndicator::Config, 
    MooseX::Getopt::Dashes) {
    use App::Syndicator::Store;
    use App::Syndicator::Importer;
    use App::Syndicator::View::Console;
    use MooseX::Types::Moose qw/Bool/;
    use App::Syndicator::Types ':all';

    our $VERSION = 0.001;

    has store => (
        is => 'rw',
        isa => Store_T,
        required => 1,
        default => sub {
            App::Syndicator::Store->new;
        },
    );

    has importer => (
        is => 'rw',
        isa => Importer_T,
        lazy_build => 1,
        required => 1,
    );

    has view => (
        is => 'rw',
        isa => View_T,
        default => sub {
            App::Syndicator::View::Console->new;
        },
        handles => [qw/display display_error/],
    );

    # parameters

    has show_entries => (
        is => 'ro',
        isa => PositiveInt,
    );

    has tick => (
        is => 'ro',
        isa => Bool,
    );

    has fetch_interval => (
        is => 'rw',
        isa => PositiveInt,
        default => sub { 300 },
    );

    has +configfile => (
        is => 'ro',
        required => 1,
        isa => File,
        default => sub {"config"},
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
        $self->display(
            $self->importer->retrieve
        );

        $self->display_error($self->importer->errors)
            if $self->importer->errors;

        $self->ticker if $self->tick;
    }

    method ticker {
        while(sleep $self->fetch_interval) {
            $self->display($self->store->unread);
            $self->store->mark_read;
        }
    }
}


1;
__END__

=head1 NAME

App::Syndicator - Perl application for feed syndication

=head1 SYNOPSIS

 $ syndicator --show-entries 10 | less -r

=head1 SEE ALSO

XML::Feed XML::Feed::Aggregator

=head1 AUTHOR

Rob Edwards, E<lt>rge@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Rob Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
