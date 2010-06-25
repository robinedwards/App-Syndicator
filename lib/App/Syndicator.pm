package App::Syndicator;
use MooseX::Declare;

our $VERSION = '0.01';

class App::Syndicator with (App::Syndicator::Config,
    App::Syndicator::TextFilter, 
    App::Syndicator::TextDraw, 
    MooseX::Getopt::Dashes) {

    use XML::Feed;
    use MooseX::Types::URI 'Uri';
    use MooseX::Types::DateTime 'DateTime';
    use MooseX::Types -declare=>[qw/UriArray/];
    use MooseX::Types::Moose qw/ArrayRef Str/;
    
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
            list_feeds => 'keys',
        }
    );

    method run {
        $self->load_feeds;
        $self->show_feeds;
    }

    method show_feeds {
        for my $feed (map { $self->get_feed($_) } $self->feed_uri) {
            $self->d_hr;
            $self->d_feed_title($feed->{title});

            for my $feed (@{$feed->{entries}}) {
                $self->d_hr;
                $self->d_title("$feed->{title} - $feed->{date}");
                $self->d_link($feed->{link});
                $self->d_say($feed->{content});
            }
        }
    }

    method load_feeds {
        $self->d_say("Loading content");
        $| = 1;

        for ($self->feed_uri) {
            my ($title, $entries) = $self->fetch_feed($_);
            next unless $title;

            $self->cache->{$_->as_string}{title} = $title;
            push @{$self->cache->{$_->as_string}{entries}}, @$entries;
        }

        $self->d_say("done.");
    }

    method fetch_feed (Uri $uri, DateTime $last?) {
        my $feed = XML::Feed->parse($uri);
        
        unless ($feed) {
            $self->d_error("\n".$uri->as_string." failed.");
            return;
        }

        my @entries;
        
        for ($feed->entries)  { 
            print "."; 

            my $dt = $_->issued || $_->modified;
            last if ($last and $last->compare($dt) >= 0);

            push @entries, {
                title => $self->to_ascii($_->title),
                content => $self->to_ascii($_->content->body 
                    || $_->summary->body),
                link => $_->link,
                issued => $dt,
                date => $dt ?  
                    $dt->ymd('-')." ".$dt->ymd(':')
                    : '???',
            };
        }

        return ($feed->title, \@entries);
    }

}


1;
__END__

=head1 NAME

App::Syndicator - Perl application for feed syndicationh

=head1 SYNOPSIS

 $ syndicator | less -r

=head1 DESCRIPTION

...

=head1 SEE ALSO

...

=head1 AUTHOR

Rob Edwards, E<lt>rge@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Rob Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
