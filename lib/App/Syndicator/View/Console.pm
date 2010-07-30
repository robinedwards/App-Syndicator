use MooseX::Declare;

class App::Syndicator::View::Console {
    use Term::ANSIColor;
    use App::Syndicator::Types ':all';
    require HTML::TreeBuilder;
    require HTML::FormatText;

    method display (@entries) {
        $self->display_entry($_) for (@entries);
    }

    method display_error (@error) {
        $self->title("The following errors occured");
        $self->error($_) for (@error);
    }

    method display_entry ($entry) {
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

    method error ($arg) {    
        print  color('red'), ascii(@$arg), color('reset'), "\n";
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
        $text =~ s/\[IMAGE\]//g;
        $text =~ s/^(\s+)\S//g;
        $text =~ s/(\s+)$//g;
        chomp($text);
        return $text;
    }
}

