package App::Syndicator;
use MooseX::Declare;

class App::Syndicator with (App::Syndicator::Config, 
    MooseX::Getopt::Dashes) {
    use App::Syndicator::Store;
    use App::Syndicator::View::Console;
    use MooseX::Types::Moose qw/Str Object ArrayRef/;

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
        handles => [qw/latest entries/]
    );

    has view => (
        is => 'rw',
        isa => Object,
        default => sub {
            App::Syndicator::View::Console->new;
        }
    );

    method BUILD {
        $self->store(
            App::Syndicator::Store->new(sources=>$self->sources)
        );
    }

    method run {
        $self->view->display($self->entries);
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
