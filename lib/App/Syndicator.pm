use Devel::SimpleTrace;
use MooseX::Declare;

class App::Syndicator with (App::Syndicator::Config, 
    MooseX::Getopt::Dashes) {
    use App::Syndicator::Store;
    use App::Syndicator::View::Console;
    use MooseX::Types::Moose qw/Str Int/;
    use App::Syndicator::Types ':all';

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
        isa => UriArray,
        coerce => 1,
    );

    # list of rss / atom feeds uri
    has store => (
        is => 'rw',
        isa => 'App::Syndicator::Store',
        required => 0,
        handles => [qw/unread entries since/]
    );

    has show_entries => (
        is => 'rw',
        isa => Int,
    );

    has view => (
        is => 'rw',
        isa => View_T,
        default => sub {
            App::Syndicator::View::Console->new;
        },
        handles => [qw/display display_error/],
    );

    has fetch_interval => (
        is => 'rw',
        isa => Int,
        default => sub { 300 },
    );

    method BUILD {
        $self->store(
            App::Syndicator::Store->new(sources => $self->sources)
        );
    }

    method run {
        $self->display($self->entries);
        $self->display_error($self->store->errors);
        $self->ticker;
    }

    method ticker {
        while(1) {
            $self->display($self->store->unread);
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
