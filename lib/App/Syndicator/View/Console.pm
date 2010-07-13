use MooseX::Declare;

use Moose::Util::TypeConstraints;
sub BEGIN { class_type 'XML::Feed::Entry'; };

class App::Syndicator::View::Console {
    use Term::ANSIColor;
    use Data::Dumper;
    require HTML::TreeBuilder;
    require HTML::FormatText;

    method display (@entries) {
        $self->entry($_) for (@entries);
    }

    method entry ($entry) {
        $self->hr;

        my $date = $entry->issued || $entry->modified;

        $self->title($date->dmy('-').' '.$date->hms(':')
            .' | '.$entry->title);

        $self->hr;
        $self->write($entry->content->body || $entry->summary->body);
    }

    method error (@arg) {    
        print  color('red'), ascii(@arg), color('reset'), "\n";
    }

    method title (@arg) {
        print  color('bold white'), ascii(@arg), color('reset'), "\n";
    }

    method write (@arg) {
        print color('white'), ascii(@arg), color('reset'), "\n";
    }

    method link (@arg) {
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

