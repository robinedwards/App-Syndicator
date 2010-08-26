use MooseX::Declare;

class App::Syndicator::UI with App::Syndicator::HtmlToAscii {
    use App::Syndicator::Types ':all';
    use App::Syndicator::Importer;
    use MooseX::Types::Moose 'ArrayRef';
    use Try::Tiny;
    use Curses::UI;

    has curses => ( 
        is => 'ro',
        isa => Curses_T,
        required => 1, 
        default =>  sub { 
            Curses::UI->new(
                -color_support => 1,
                -clear_on_exit => 1
            ) 
        }, 
        handles => [qw/set_binding mainloop schedule_event/]
    );

    has sources => (
        is => 'rw',
        isa => UriArray,
        coerce => 1,
        traits => ['Array'],
        handles => {
            source_count => 'count'
        }
    );

    has new_entries => (
        is => 'rw',
        isa => ArrayRef[Entry_T],
        traits => ['Array'],
        default => sub {[]},
        handles => {
            get_entry => 'get',
            entry_count => 'count', 
        },
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
        $self->bind_keys;

        $self->home;
    }

    method bind_keys {
        $self->set_binding( sub { exit }, 'q');
        $self->set_binding( sub { $self->next_entry }, 'n');
        $self->set_binding( sub { $self->previous_entry }, 'p');
        $self->set_binding( sub { $self->fetch_entries }, 'f');
        $self->set_binding( sub { $self->list_entries }, 'l');
        $self->set_binding( sub { $self->home }, 'h');
    }

    method next_entry {
        unless ($self->entry_count) {
            $self->status_text("No entries..");
            return;
        }

        $self->inc_index;
        my $entry = $self->get_entry($self->index);
        $self->display_entry($entry);
    }

    method previous_entry {
        unless ($self->entry_count) {
            $self->status_text("No entries..");
            return;
        }

        $self->dec_index if $self->index > 0;
        my $entry = $self->get_entry($self->index);
        $self->display_entry($entry);
    }

    method fetch_entries {
        $self->status_text('Fetching entries..');
        $self->status_bar->focus;

        $self->schedule_event(sub { $self->fetch_new_entries } );
    }

    method fetch_new_entries {
        my $importer;

        try {
            $importer = App::Syndicator::Importer->new(
                sources => $self->sources,
            );
        }

        catch {
            $self->viewer_text("Fetch failed:\n$_");
            $self->status_text('Error');
        }

        finally {
            $self->new_entries([$importer->retrieve]);
            $self->viewer_text( "\nFetched "
                . $importer->count . " entries from " 
             . $self->source_count . " sources."
            );
            $self->status_text('Finished.');
        };
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

    method home {
        my $HELP_MESSAGE = "\nWelcome!\n"
            . "n - next entry\n"
            . "p - previous entry\n"
            . "q - quit\n"
            . "f - fetch entries\n"
            . "h - help (this screen)\n";
    
        $self->status_text('Home');
        $self->viewer_text($HELP_MESSAGE);
    }
    
    method viewer_text (Str $text){
        $self->viewer->text($text);
        $self->viewer->focus;
    }

    method status_text (Str $text?) {
        $text =~ s/\n//g;

        $self->set_status_text(
            "App::Syndicator v"
            . $App::Syndicator::VERSION
            . " - $text"
        );

        $self->status_bar->focus;
    }

    method _index_set (PositiveInt $index, PositiveInt $old_index) {
        $self->index(0) and return unless $self->entry_count;

        if ($index > $self->entry_count) {
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

