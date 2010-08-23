use MooseX::Declare;

class App::Syndicator::UI with App::Syndicator::HtmlToAscii {
    use App::Syndicator::Types ':all';
    use MooseX::Types::Moose 'ArrayRef';
    use Curses::UI;

    has curses => ( 
        is => 'ro',
        isa => Curses_T,
        required => 1, 
        default =>  sub { 
            Curses::UI->new(
                -color_support => 1
                -clear_on_exit => 1
            ) 
        }, 
        handles => [qw/set_binding mainloop/]
    );

    has entries => (
        is => 'ro',
        isa => ArrayRef[Entry_T],
        required => 1,
        traits => ['Array'],
        handles => {
            get_entry => 'get',
            entry_count => 'count', 
        }
    );

    has index => (
        is => 'rw',
        isa => PositiveInt,
        traits => ['Counter'],
        default => 0,
        handles => {
            inc_index => 'inc',
            dec_index => 'dec',
            reset_index => 'reset'
        },
        predicate => 'entries',
        trigger => \&_index_set
    );

    has main_window => (
        is => 'rw',
        isa => Window_T,
        required => 1,
        lazy_build => 1
    );

    has status_window => (
        is => 'rw',
        isa => Window_T,
        required => 1,
        lazy_build => 1
    );

    has viewer => ( 
        is => 'rw',
        isa => TextViewer_T, 
        required => 1,
        lazy_build => 1,
        handles => {
            viewer_text => 'text' 
        }
    );

    has status_bar => ( 
        is => 'rw',
        isa => TextViewer_T, 
        required => 1,
        lazy_build => 1,
        handles => {
            set_status_text => 'text' 
        }
    );

    our $HELP_MESSAGE = "\nWelcome!\n"
        . "n - next entry\n"
        . "p - previous entry\n"
        . "q - quit\n"
        . "h - this screen\n";
    
    method BUILD {
        my $statuswin = $self->curses->add(
            'status', 'Window',
            -y => 0,
            -height => 1,
            -bg => 'blue',
            -fg => 'white',
        );

        my $mainwin = $self->curses->add(
            'main', 'Window',
            -y => 1,
            -border => 0,
        );

        $self->main_window($mainwin);
        $self->status_window($statuswin);

        my $textview = $self->main_window->add(
            'reader', 'TextViewer',
        );

        my $statusbar = $self->status_window->add(
            'reader', 'TextViewer',
        );

        $self->viewer($textview);
        $self->viewer->focus;
        $self->status_bar($statusbar);
        $self->status_text("Help");
        $self->viewer_text($HELP_MESSAGE);

        $self->bind_keys;
    }

    method bind_keys {
        $self->set_binding( sub { exit }, 'q');
        $self->set_binding( sub { $self->next_entry }, 'n');
        $self->set_binding( sub { $self->previous_entry }, 'p');
        $self->set_binding( sub { $self->list_entries }, 'l');
        $self->set_binding( sub { $self->help }, 'h');
    }

    method next_entry {
        $self->inc_index;
        my $entry = $self->get_entry($self->index);
        $self->display_entry($entry);
    }

    method previous_entry {
        $self->dec_index if $self->index > 0;
        my $entry = $self->get_entry($self->index);
        $self->display_entry($entry);
    }


    method display_entry (Entry_T $entry?) {
        return unless $entry;

        my $html = $entry->content->body
            || $entry->summary->body;

        my $body = $self->html_to_ascii($html);

        my $date = $entry->issued || $entry->modified;

        my $title = $date->dmy('-').' '.$date->hms(':')
            .' - '.$entry->title;

        $title =~ s/\n//g;

        $self->viewer_text("\n$title\n\n$body\n\n".$entry->link);
    }

    method help {
        $self->viewer_text($HELP_MESSAGE);
    }

    method status_text (Str $text?) {
        chomp $text;
        $self->set_status_text(
            "App::Syndicator v"
            . $App::Syndicator::VERSION
            . " - $text"
        );

        $self->status_bar->focus;
    }

    method _index_set (PositiveInt $index, PositiveInt $old_index) {
        if ($index >= $self->entry_count) {
            $self->index($old_index);
        }

        $self->status_text(
            "Viewing item " 
            . $self->index
            . "/" . $self->entry_count
            . "."
        );
    }
}

