use MooseX::Declare;

class App::Syndicator::Store {
    use MooseX::Storage;
    use MooseX::MultiMethods;
    use MooseX::Types::Moose qw/ArrayRef HashRef/;
    use App::Syndicator::Types qw/Entry_T PositiveInt DateTime_T/;
    use XML::Feed::Aggregator;

    with Storage('format' => 'JSON');

    has last_read => (
        is => 'rw',
        isa => DateTime_T,
    );

    has entry => (
        is => 'rw',
        isa => HashRef,
        traits => [HashRef],
        default => sub{ {} },
        handles => {
            _remove_entry => 'del',
            _add_entry => 'set',
            _all => 'keys'
        }
    );

    method add_entry (Entry_T $entry) {
        $self->_add_entry($entry->id, $entry);
    }

    multi method remove_entry (Entry_T $entry) {
        $self->_remove_entry($entry->id);
    }

    multi method remove_entry (PositiveInt $id) {
        $self->_remove_entry($id);
    }
}

1;
