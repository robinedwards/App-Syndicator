use MooseX::Declare;

role App::Syndicator::FeedReader {
    use XML::Feed::Aggregator;
    use App::Syndicator::Types qw/
    UriArray Aggregator_T
    /;

    # list of rss / atom uris
    has sources => (
        is => 'ro',
        isa => UriArray,
        traits => ['Array'],
        coerce => 1,
        required => 1,
    );

    has aggregator => (
        is => 'rw',
        isa => Aggregator_T,
        handles => [qw/errors/],
    );

    method fetch_feeds {
        $self->aggregator(
            XML::Feed::Aggregator->new({
                sources => $self->sources
            })
        );

        $self->aggregator->sort('desc');
        $self->aggregator->deduplicate;
    }
}
