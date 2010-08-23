use MooseX::Declare;

role App::Syndicator::HtmlToAscii {
    require HTML::TreeBuilder;
    require HTML::FormatText;

    method html_to_ascii (Str|Undef $html?) {
        return '' unless $html;
        my $tree = HTML::TreeBuilder->new_from_content($html);
        my $formatter = HTML::FormatText->new;
        my $text = $formatter->format($tree);
        return _filter($text);
    }

    sub _filter {
        my $text = shift;
        $text =~ s/Read more of this story at Slashdot\.//g;
        $text =~ s/\[IMAGE\]//g;
        $text =~ s/^(\s+)\S//g;
        $text =~ s/(\s+)$//g;
        chomp($text);
        return $text;
    }
}

1;
