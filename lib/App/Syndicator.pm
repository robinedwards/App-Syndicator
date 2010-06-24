package App::Syndicator;
use MooseX::Declare;

our $VERSION = '0.01';

class App::Syndicator with (App::Syndicator::Config,
    App::Syndicator::TextFilter, 
    App::Syndicator::TextDraw, 
    MooseX::Getopt::Dashes) {

    use XML::Feed;
    use MooseX::Types::URI 'Uri';
    use MooseX::Types -declare=>[qw/UriArray/];
    use MooseX::Types::Moose qw/ArrayRef Str/;
    use Data::Dumper;
    
    subtype UriArray,
        as ArrayRef[Uri];

    coerce UriArray, from ArrayRef[Str],
    via sub {
        my @uri = map { Uri->coerce($_) } @{$_[0]};
        return \@uri;
    };

    has +configfile => (
        is => 'ro',
        required => 1,
        isa => 'Str',
        default => sub {"config"},
    );

    # list of rss / atom feeds uri
    has feed => (
        is => 'ro',
        isa => UriArray,
        traits => ['Array'],
        coerce => 1,
        handles => {
            feed_uri => 'elements',
        }
    );

    # store of feed content
    has cache => (
        is => 'ro',
        isa => 'HashRef',
        traits => ['Hash'],
        default => sub { {} },
        handles => {
            get_feed => 'get',
            set_feed => 'set',
            list_feeds => 'keys',
        }
    );

    method run {
        $self->d_say("Loading content");
        $| = 1;
        my $e = 0; 
        $e += $self->fetch($_) for ($self->feed_uri);
        $self->d_say("($e) done.");

        $self->show_feeds;
    }

    method show_feeds {
        for my $title ($self->list_feeds) {
            $self->d_hr;
            $self->d_feed_title($title);

            for my $feed (@{$self->get_feed($title)}) {
                $self->d_hr;
                $self->d_title("$feed->{title} - $feed->{date}");
                $self->d_link($feed->{link});
                $self->d_say($feed->{content});
            }
        }
    }

    method fetch (Uri $uri) {
        my $feed = XML::Feed->parse($uri);
        
        unless (defined $feed) {
            $self->d_error("\n".$uri->as_string." failed.");
            return 0;
        }

        my @entries = map { 
            print '.'; 
            my $dt = $_->issued || $_->modified;
            {
                title => $self->to_ascii($_->title),
                content => $self->to_ascii($_->content->body || $_->summary->body),
                link => $_->link,
                issued => $dt,
                date => $dt ?  
                    $dt->ymd('-')." ".$dt->ymd(':')
                    : '???',
            };
        } $feed->entries;


        $self->set_feed($self->to_ascii($feed->title), \@entries);
        return scalar(@entries);
    }

}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

App::Syndicator - Perl extension for blah blah blah

=head1 SYNOPSIS

  use App::Syndicator;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for App::Syndicator, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Rob Edwards, E<lt>robin.ge@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Rob Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
