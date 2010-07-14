use MooseX::Declare;

class App::Syndicator with (App::Syndicator::Config, 
    MooseX::Getopt::Dashes) {
    use App::Syndicator::Store;
    use App::Syndicator::View::Console;
    use AnyEvent;
    use MooseX::Types::Moose qw/Str Object ArrayRef Int/;

    our $VERSION = '0.01';
    
    has +configfile => (
        is => 'ro',
        required => 1,
        isa => Str,
        default => sub {"config"},
    );

    has sources => (
        is => 'rw',
        required => 1,
        isa => ArrayRef[Str],
    );

    # list of rss / atom feeds uri
    has store => (
        is => 'rw',
        isa => 'App::Syndicator::Store',
        required =>0,
        handles => [qw/latest entries since/]
    );

    has view => (
        is => 'rw',
        isa => Object,
        default => sub {
            App::Syndicator::View::Console->new;
        },
        handles => [qw/display/],
    );

    has fetch_interval => (
        is => 'rw',
        isa => Int,
        default => sub { 30 },
    );

    method BUILD {
        $self->store(
            App::Syndicator::Store->new(sources=>$self->sources)
        );
    }

    method run {
        # display all
        $self->display($self->store->feed->entries);
        $self->loop;
    }

    method loop {
        while(1) {
            $self->display($self->store->get_latest);
            $self->store->mark_read;
            sleep $self->fetch_interval;
        }
    }
}


1;
__END__

=head1 NAME

App::Syndicator - Perl application for feed syndication

=head1 SYNOPSIS

 $ syndicator | less -r

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
