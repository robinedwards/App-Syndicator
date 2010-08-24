use MooseX::Declare;

class App::Syndicator::View::Console with App::Syndicator::HtmlToAscii {
    use App::Syndicator::Types ':all';
    use MooseX::Types::Moose qw/ArrayRef Str/;
    use Term::ANSIColor;

    has entries => (
        is => 'ro',
        isa => ArrayRef[Entry_T],
        required => 1,
    );

    has errors => (
        is => 'ro',
        isa => ArrayRef[Str],
        default => sub { [] }
    );

    has colour => (
        is => 'ro',
        isa => 'Bool',
        required => 1,
        default => 0,
    );

    method run {
        $self->_display_entry($_) for ($self->entries);

        $self->_error($_) for ($self->errors);
    }

    method _display_entry (Entry_T $entry) {
        $self->_hr;

        my $date = $entry->issued || $entry->modified;

        $self->_title($date->dmy('-').' '.$date->hms(':')
            .' | '.$entry->title);

        $self->_hr;

        my $c = $b = $entry->content->body;
        my $s = $entry->summary->body;

        if (defined $c) {
            $b = ( length($c) >= length($s)) ? $c : $s
                if (defined $s);
        }
        else {
             $b = $s;
        }
        
        $self->_write($b);

        $self->_link($entry->link);
    }

    method _colour (Str $colour) {
        color ($colour) if $self->colour;
    }

    method _error (Str @arg) {    
        print STDERR $self->_colour('red')
            . $self->html_to_ascii(@arg)
            . $self->_colour('reset') . "\n";
    }

    method _title (Str @arg) {
        print  $self->_colour('bold white')
            . $self->html_to_ascii(@arg)
            . $self->_colour('reset') . "\n";
    }

    method _write (Str @arg) {
        print $self->_colour('white')
            . $self->html_to_ascii(@arg)
            . $self->_colour('reset') . "\n";
    }

    method _link (Str @arg) {
        print  $self->_colour('green')
            . $self->html_to_ascii(@arg)
            . $self->_colour('reset')
            . "\n";
    }
    
    method _hr {
        print  '-' x 80, "\n";
    }
}

