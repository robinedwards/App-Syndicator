use MooseX::Declare;

class App::Syndicator::DB {
    use KiokuDB;
    use XML::Feed::Aggregator;
    use App::Syndicator::Message;
    use App::Syndicator::Types qw/
        KiokuDB_T Message_T UriArray Aggregator_T
        /;
    use MooseX::Types::Moose 'Str';

    has dsn => (
        is => 'ro',
        isa => Str,
        required => 1,
        default => "dbi:SQLite:dbname=$ENV{HOME}/.syndicator.db"
    );

    has directory => (
        is => 'rw',
        isa => KiokuDB_T,
        required => 1,
        lazy_build => 1,
        predicate => 'dsn',
        handles => [qw/delete lookup/]
    );

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

    method fetch {
        $self->aggregator(
            XML::Feed::Aggregator->new({
                sources => $self->sources
            })
        );
        $self->aggregator->sort('desc');
        $self->aggregator->deduplicate;
        
        my $n = 0;

        for my $entry ($self->aggregator->entries) {
            $n++ if $self->store(
                App::Syndicator::Message->new($entry)
            );
        }

        return $n;
    } 


    method _build_directory {
        $self->directory(
            KiokuDB->connect(
                $self->dsn,
                create => 1
            )
        );
    }

    # TODO setup root for messages
    method store (Message_T $msg) {
        return if $self->lookup($msg->id);
        return 1
           if ($self->directory->store($msg->id => $msg));
    }

    method all_messages {
        return $self->directory->all_objects->items;
    }
}

1;
