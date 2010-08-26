use MooseX::Declare;

class App::Syndicator::Importer {
    use MooseX::MultiMethods;
    use App::Syndicator::Types qw/
        UriArray PositiveInt
        Aggregator_T DateTime_T
        /;
    use XML::Feed::Aggregator;

    # list of rss / atom uris
    has sources => (
        is => 'ro',
        isa => UriArray,
        traits => ['Array'],
        coerce => 1,
    );

    # master aggregated feed
    has aggregator => (
        is => 'rw',
        isa => Aggregator_T,
        required => 1,
        lazy_build => 1,
        handles => [qw/errors/],
    );

    method BUILD {
        $self->aggregator(
            XML::Feed::Aggregator->new({
                sources => $self->sources
            })
        );
        $self->aggregator->sort('desc');
        $self->aggregator->deduplicate;
    }

    multi method retrieve (Undef $p?) {
        return $self->aggregator->entries;
    }

    multi method retrieve (PositiveInt $to_return) {
        my $last_entry = scalar($self->aggregator->entries) -1;
        
        return splice @{$self->aggregator->entries}, 
            $last_entry, ($to_return * -1);
    }

    multi method retrieve (DateTime_T $since) {
        return $self->aggregator->since($since);
    }

    method count {
        return scalar($self->aggregator->entries);
    }
}


1;
