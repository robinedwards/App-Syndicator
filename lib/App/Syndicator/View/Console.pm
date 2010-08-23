use MooseX::Declare;

class App::Syndicator::View::Console {
    use App::Syndicator::Types ':all';
    use Term::ANSIColor;
    require HTML::TreeBuilder;
    require HTML::FormatText;

    method BUILD {
        $self->window (
            $self->curses->add(
                'win1', 'Window',
                -border => 1,
                -bfg  => 'red',
            )
        );
    }

    method display (Entry_T @entries) {
        $self->display_entry($_) for (@entries);
    }

    method display_error (Str @error) {
        $self->title("The following errors occured");
        $self->error($_) for (@error);
    }

    method display_entry (Entry_T $entry) {
        $self->hr;

        my $date = $entry->issued || $entry->modified;

        $self->title($date->dmy('-').' '.$date->hms(':')
            .' | '.$entry->title);

        $self->hr;

        my $c = $b = $entry->content->body;
        my $s = $entry->summary->body;

        if (defined $c) {
            $b = ( length($c) >= length($s)) ? $c : $s
                if (defined $s);
        }
        else {
             $b = $s;
        }
        
        $self->write($b);

        $self->link($entry->link);
    }

    method error (Str @arg) {    
        print  color('red'), ascii(@arg), color('reset'), "\n";
    }

    method title (Str @arg) {
        print  color('bold white'), ascii(@arg), color('reset'), "\n";
    }

    method write (Str @arg) {
        print color('white'), ascii(@arg), color('reset'), "\n";
    }

    method link (Str @arg) {
        print  color('green'), ascii(@arg), color('reset'), "\n";
    }
    
    method hr {
        print  '-' x 80, "\n";
    }

    sub ascii {
        my $tree = HTML::TreeBuilder->new_from_content(@_);
        
        my $formatter = HTML::FormatText->new(
            leftmargin => 0, rightmargin => 80);
        my $text = $formatter->format($tree);

        return filter($text);
    }

    sub filter {
        my $text = shift;
        $text =~ s/Read more of this story at Slashdot\.//g;
        $text =~ s/\[IMAGE\]//g;
        $text =~ s/^(\s+)\S//g;
        $text =~ s/(\s+)$//g;
        chomp($text);
        return $text;
    }
}

