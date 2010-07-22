use MooseX::Declare;

class App::Syndicator::Store {
    use MooseX::Types::Moose qw/ArrayRef/;
    use App::Syndicator::Types ':all';
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
        handles => [qw|since|]
    );

    has last_read => (
        is => 'rw',
        isa => DateTime_T,
    );

    method BUILD {
        $self->refresh;
        $self->mark_read;
    }

    method refresh {
        my $agg = XML::Feed::Aggregator->new({sources=>$self->sources});
        $agg->sort('desc');
        $self->aggregator($agg);
    }

    method unread {
        $self->refresh;
        my @entries = $self->aggregator->since($self->last_read);
        $self->mark_read;
        return @entries;
    }

    method _last_entry {
        return scalar(@{$self->aggregator->entries}) - 1;
    }

    method mark_read {
        $self->last_read(
            $self->aggregator->entries->[$self->_last_entry]->issued
            || 
            $self->aggregator->entries->[$self->_last_entry]->modified
        );
    }

    method entries (Int|Undef $to_return?) {
        if ($to_return) {
            return splice @{$self->aggregator->entries}, 
                $self->_last_entry, ($to_return * -1);
        }

        return @{$self->aggregator->entries};
    }
}


1;
