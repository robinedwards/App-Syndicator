use MooseX::Declare;

class App::Syndicator::Store {
    use MooseX::Types -declare=>['UriArray'];
    use MooseX::Types::Moose qw/ArrayRef Str/;
    use MooseX::Types::URI 'Uri';
    use DateTime;
    
    use XML::Feed::Aggregator;
    
    subtype UriArray,
        as ArrayRef[Uri];

    coerce UriArray, from ArrayRef[Str],
    via sub {
        [ map { Uri->coerce($_) } @{$_[0]} ];
    };

    # list of rss / atom uris
    has sources => (
        is => 'ro',
        isa => UriArray,
        traits => ['Array'],
        coerce => 1,
    );

    # master aggregated feed
    has master => (
        is => 'rw',
        isa => 'XML::Feed::Aggregator',
        handles => [qw|entries|]
    );

    has last_read => (
        is => 'rw',
        isa => 'DateTime',
    );

    method BUILD {
        $self->refresh;
    }

    # refresh feed
    method refresh {
        my $agg = XML::Feed::Aggregator->new({uri=>$self->sources});
        $agg->sort;
        $self->master($agg);
        $self->last_read(DateTime->now);
    }

    method latest {
        return $self->master->since($self->last_read);
    }
}


1;
