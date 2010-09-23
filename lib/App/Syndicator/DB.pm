use MooseX::Declare;

class App::Syndicator::DB {
    use KiokuDB;
    use XML::Feed::Aggregator;
    use DateTime;
    use App::Syndicator::Message;
    use App::Syndicator::Types qw/
        KiokuDB_T Message_T UriArray Aggregator_T
        /;
    use MooseX::Types::Moose qw/Str Int/;

    has dsn => (
        is => 'rw',
        isa => Str,
        required => 1,
    );

    has directory => (
        is => 'rw',
        isa => KiokuDB_T,
        required => 1,
        lazy_build => 1,
        handles => [qw/lookup search store delete/]
    );

    has scope => (
        is => 'rw',
        isa => 'Object',
        lazy_build => 1,
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

    has total => (
        is => 'rw',
        isa => Int,
        traits => ['Counter'],
        default => 0,
        handles => {
            inc_total => 'inc',
            dec_total => 'dec',
        }
    );

    has unread => (
        is => 'rw',
        isa => Int,
        default => 0,
        traits => ['Counter'],
        handles => {
            inc_unread => 'inc',
            dec_unread => 'dec',
        }
    );

    method BUILD {
        $self->directory(
            KiokuDB->connect(
                $self->dsn,
                create => 1,
                columns => [
                    is_read => {
                        data_type => "boolean",
                        is_nullable => 0,
                    },
                    is_deleted => {
                        data_type => "boolean",
                        is_nullable => 0,
                    },
                    star => {
                        data_type => "boolean",
                        is_nullable => 0,
                    },
                    title => {
                        data_type => "text",
                        is_nullable => 0,
                    },
                    body => {
                        data_type => "text",
                        is_nullable => 0,
                    },
                    published => {
                        data_type => "datetime",
                        is_nullable => 1,
                    },
                ]
            )
        );

        $self->scope(
            $self->directory->new_scope
        );
    }

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
                $self->inc_unread;
                $self->inc_total;
            }
        }

        return sort {
            $b->published->compare($a->published)
        } @new_messages;
    } 

    method all_messages {
        my @msg = map { 
            $self->inc_total;
            $self->inc_unread unless $_->is_read;
            $_;
        } sort {
            $b->published->compare($a->published)
        } 
        $self->directory->search(
            {is_deleted => 0},
        )->all;
    }

}

1;
