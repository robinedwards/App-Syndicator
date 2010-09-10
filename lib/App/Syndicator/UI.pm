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

    has entry_dict => (
        is => 'rw',
        isa => 'HashRef',
        default => sub {{}},
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

    has header_window => (
        is => 'rw',
        isa => Window_T,
        required => 1,
        lazy_build => 1
    );

    has list_window => (
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

    has header_bar => ( 
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
    );

    has list_box => ( 
        is => 'rw',
        isa => ListBox_T, 
        required => 1,
        lazy_build => 1,
    );

    method _build_status_window {
        my $status_win = $self->curses->add(
            'status', 'Window',
            -y => 0,
            -height => 1,
            -bg => 'blue',
            -fg => 'white',
        );

        $self->status_window($status_win);
    }

    method _build_main_window {
        my $main_win = $self->curses->add(
            'main', 'Window',
            -y => 10,
            -border => 0,
        );

        $self->main_window($main_win);
    }

    method _build_header_window {
        my $header_win = $self->curses->add(
            'header', 'Window',
            -y => 9,
            -height => 1,
            -bg => 'blue',
            -fg => 'white',
        );

        $self->header_window($header_win);
    }

    method _build_list_window {
        my $list_win = $self->curses->add(
            'list', 'Window',
            -y => 1,
            -height => 8,
            -border => 0,
        );

        $self->list_window($list_win);
    }

    method BUILD {
        my $status_bar = $self->status_window->add(
            'status', 'TextViewer',
        );

        $self->status_bar($status_bar);

        my $textview = $self->main_window->add(
            'reader', 'TextViewer',
        );

        $self->viewer($textview);

        my $header_bar = $self->header_window->add(
            'header', 'TextViewer',
        );

        $self->header_bar($header_bar);

        my $listbox = $self->list_window->add(
            'list', 'Listbox',
            -multi => 1,
            -values => [1],
            -labels => {1 => 'No messages'},
            -onselchange => sub { $self->_list_box_change(@_) } 
        );

        $self->list_box($listbox);

        $self->_bind_keys;
        $self->home;
    }

    method _bind_keys {
        $self->set_binding( sub { exit }, "\cq");
        $self->set_binding( sub { $self->fetch_entries }, "\cf");
        $self->set_binding( sub { $self->home }, "\ch");
    }

    method _list_entries (Entry_T @entries) {
        $self->list_box->values( 
          [  map { $_->id } @entries ]
        );

        $self->list_box->labels(
            { map { $_->id => $_->title } @entries }
        );

        $self->list_box->focus;
    }

    method _list_box_change {
        my $entry_id = $self->list_box->get_active_value;
        
        return unless defined $entry_id;

        my $entry = ${$self->entry_dict->{$entry_id}};

        die "Couldn't find entry with id: $entry_id"
            unless $entry;

        $self->_render_entry_header($entry);
        $self->_render_entry_body($entry);
        $self->list_box->focus;
    }

    method fetch_entries {
        $self->status_text('Fetching entries..');
        $self->status_bar->focus;
        $self->schedule_event(sub { $self->_fetch_new_entries } );
    }

    method home {
        my $HELP_MESSAGE = "\nWelcome!\n"
            . "ctrl + q - quit\n"
            . "ctrl + f - fetch entries\n"
            . "ctrl + h - help (this screen)\n";
    
        $self->status_text('Home');
        $self->viewer_text($HELP_MESSAGE);
    }

    method _fetch_new_entries {
        my $importer;

        try {
            $importer = App::Syndicator::Importer->new(
                sources => $self->sources
            );
        }

        catch {
            $self->viewer_text("Fetch failed:\n$_");
            $self->status_text('Error');
        }

        finally {
            $self->new_entries([$importer->retrieve]);
            $self->status_text( "Fetched "
                . $importer->count . " entries from " 
             . $self->source_count . " sources."
            );
        };

        $self->entry_dict({
            map { $_->id => \$_ } 
                @{$self->new_entries}
        });
        $self->_list_entries(@{$self->new_entries});
    }

    method _render_entry_body (Entry_T $entry) {
        return unless $entry;

        my $html = $entry->content->body
            || $entry->summary->body;

        my $body = $self->html_to_ascii($html);

        $self->viewer_text("$body\n\n".$entry->link);
    }

    method _render_entry_header (Entry_T $entry) {
        my $date = $entry->issued || $entry->modified;

        my $title = $date->dmy('-').' '.$date->hms(':')
            .' - '.$entry->title ;

        $title =~ s/\n//g;

        $self->header_bar->text($title);
        $self->header_bar->focus;
    }

    
    method viewer_text (Str $text){
        $self->viewer->text($text);
        $self->viewer->focus;
    }

    method status_text (Str $text?) {
        $text =~ s/\n//g;

        $self->status_bar->text(
            "App::Syndicator v"
            . $App::Syndicator::VERSION
            . " - $text"
        );

        $self->status_bar->focus;
    }
}

