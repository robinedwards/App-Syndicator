use MooseX::Declare;

class App::Syndicator::DB {
    use KiokuDB;
    use XML::Feed::Aggregator;
    use DateTime;
    use App::Syndicator::Message;
    use App::Syndicator::Types qw/
        KiokuDB_T Message_T UriArray Aggregator_T
        /;
    use MooseX::Types::Moose 'Str';

    has dsn => (
        is => 'ro',
        isa => Str,
        required => 1,
        default => "DBI:SQLite:dbname=$ENV{HOME}/.syndicator.db"
    );

    has directory => (
        is => 'rw',
        isa => KiokuDB_T,
        required => 1,
        lazy_build => 1,
        handles => [qw/delete lookup update store/]
    );

    has scope => (
        is => 'rw',
        isa => 'Object',
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

        my @new_messages;

        for my $entry ($self->aggregator->entries) {
            my $msg = eval { App::Syndicator::Message->new($entry) };
            next unless $msg;
            next if eval { $self->lookup($msg->id) };

            if ($self->directory->store($msg->id => $msg)) {
               push @new_messages, $msg;
            }
        }

        return @new_messages;
    } 


    method BUILD {
        $self->directory(
            KiokuDB->connect(
                $self->dsn,
                create => 1
            )
        );

        $self->scope(
            $self->directory->new_scope
        );
    }

    method all_messages {
        return sort {
            $b->published->compare($a->published)
        } $self->directory->all_objects->items;
    }
}

1;
