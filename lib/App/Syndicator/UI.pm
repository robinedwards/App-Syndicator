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

        $self->_bind_keys;
        $self->home;
        $self->_populate_message_list(
            $self->db->all_messages
        );
    }

    method _bind_keys {
        $self->set_binding( sub { exit }, "q");
        $self->set_binding( sub { $self->fetch_messages }, "f");
        $self->set_binding( sub { $self->message_delete }, "d");
        $self->set_binding( sub { $self->home }, "h");
    }

    method _populate_message_list (Message_T @messages) {
        $self->message_list->values( 
            [  map { $_->id } @messages ]
        );

        $self->message_list->labels(
            { map { 
                $_->id => 
                    $_->is_read ? $_->title : '[UNREAD] '.$_->title
                } @messages 
            }
        );

        $self->message_list->focus;
    }

    method _message_list_change {
        my $msg_id = $self->message_list->get_active_value;
        
        return unless defined $msg_id;

        my $msg = eval { $self->db->lookup($msg_id) };
        return unless defined $msg;

        $self->_message_mark_read($msg);
        $self->_render_message($msg);
        $self->message_list->focus;
    }

    method _message_mark_read (Message_T $msg) {
        $msg->is_read(1);
        
        $self->db->store($msg);
        
        $self->message_list->labels->{$msg->id} = $msg->title;
        $self->message_list->focus;
    }

    method message_delete {
        my @selected = $self->message_list->get;
        
        $self->message_list->clear_selection;

        for my $id (@selected) {
            print STDERR "deleting $id";
            delete $self->message_list->labels->{$id};
            eval { $self->db->delete($id) };
            warn "error deleting blah $@\n" if $@;

            $self->message_list->values([
                grep { $id ne $_ } 
                    @{$self->message_list->values}
            ]);
        }

        $self->message_list->focus;
    }

    method fetch_messages {
        $self->_status_text('Fetching messages..');
        
        my @msgs = $self->db->fetch;

        my $n = scalar(@msgs);

        $self->_status_text("$n new message"
            .($n>1?'s!':'!'));

        for my $msg (@msgs) {
            push @{$self->message_list->values}, $msg->id;
            $self->message_list->labels->{$msg->id} = '[UNREAD] '.$msg->title;
        }

        $self->message_list->focus;
    }

    method home {
        my $help_txt = "\nWelcome!\n"
            . "q - quit\n"
            . "f - fetch messages\n"
            . "h - help (this screen)\n";
    
        $self->_status_text('Home');
        $self->_viewer_text($help_txt);
    }

    method _render_message (Message_T $msg) {
        my $title = $msg->published->dmy('-')
            .' '.$msg->published->hms(':')
            .' - '.$msg->title ;

        $self->header_bar->text($title);
        $self->header_bar->focus;

        $self->_viewer_text($msg->body."\n\n".$msg->link);
    }

    
    method _viewer_text (Str $text){
        $self->viewer->text($text);
        $self->viewer->focus;
    }

    method _status_text (Str $text?) {
        $text =~ s/\n//g;

        $self->status_bar->text(
            "App::Syndicator v"
            . $App::Syndicator::VERSION
            . " - $text"
        );

        $self->status_bar->focus;
    }
}

