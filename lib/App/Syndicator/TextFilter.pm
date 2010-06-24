package App::Syndicator::TextFilter;
use MooseX::Declare;

role App::Syndicator::TextFilter {
    require HTML::TreeBuilder;
    require HTML::FormatText;

    method to_ascii (Str $content) {
        my $tree = HTML::TreeBuilder->new_from_content($content);
        
        my $formatter = HTML::FormatText->new(leftmargin => 0, rightmargin => 80);
        my $text = $formatter->format($tree);

        $text =~ s/\[IMAGE\]/\ \ \ \ \ \ /g;
        $text =~ s/^(\s+)\S//g;
        $text =~ s/(\s+)$//g;
        chomp($text);

        return $text;
    }
}

1;
