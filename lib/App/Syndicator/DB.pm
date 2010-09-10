use MooseX::Declare;

class App::Syndicator::DB {
    use KiokuDB;
    use MooseX::MultiMethods;
    use Class::MOP;
    use App::Syndicator::Types ':all';

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
        handles => [qw/delete lookup store/]
    );

    method _build_directory {
        $self->directory(
            KiokuDB->connect(
                $self->dsn,
                create => 1
            );
        );
    }

    multi method mark_read (Entry_T $entry) {
        my $entry = $self->lookup($entry->id);
        $entry->_is_read(1);
        $self->store($entry);
    }
}

1;
