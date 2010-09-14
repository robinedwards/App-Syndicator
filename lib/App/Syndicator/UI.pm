use MooseX::Declare;

class App::Syndicator::UI  {
    use App::Syndicator::Types ':all';
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
    
    has db => (
        is => 'ro',
        isa => DB_T,
        required => 1,
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

    has message_list => ( 
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
            -onselchange => sub { $self->_message_list_change(@_) } 
        );

        $self->message_list($listbox);
        $self->_list_messages($self->db->all_messages);

        $self->_bind_keys;
        $self->home;
    }

    method _bind_keys {
        $self->set_binding( sub { exit }, "\cq");
        $self->set_binding( sub { $self->fetch_messages }, "\cf");
        $self->set_binding( sub { $self->home }, "\ch");
    }

    method _list_messages (Message_T @messages) {
        $self->message_list->values( 
          [  map { $_->id } @messages ]
        );

        $self->message_list->labels(
            { map { $_->id => $_->title } @messages }
        );

        $self->message_list->focus;
    }

    method _message_list_change {
        my $msg_id = $self->message_list->get_active_value;
        
        return unless defined $msg_id;

        my $msg = $self->db->lookup($msg_id);

        $self->_render_message($msg);
        $self->message_list->focus;
    }

    method fetch_messages {
        $self->status_text('Fetching messages..');
        $self->status_bar->focus;
        my $n = $self->db->fetch;
        $self->status_text("$n new message"
            .($n>1?'s!':'!'));
        $self->status_bar->focus;
    }

    method home {
        my $help_txt = "\nWelcome!\n"
            . "ctrl + q - quit\n"
            . "ctrl + f - fetch messages\n"
            . "ctrl + h - help (this screen)\n";
    
        $self->status_text('Home');
        $self->viewer_text($help_txt);
    }

    method _render_message (Message_T $msg) {
        my $title = $msg->published->dmy('-')
            .' '.$msg->published->hms(':')
            .' - '.$msg->title ;

        $self->header_bar->text($title);
        $self->header_bar->focus;

        $self->viewer_text("$msg->body\n\n".$msg->link);
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

