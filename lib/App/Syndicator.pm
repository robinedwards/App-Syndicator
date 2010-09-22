use MooseX::Declare;

class App::Syndicator with (App::Syndicator::Config, 
    MooseX::Getopt::Dashes) {
    use App::Syndicator::Types qw/File UriArray/;
    use MooseX::Types::Moose qw/Bool HashRef/;
    use App::Syndicator::UI;
    use App::Syndicator::DB;

    our $BASE = "$ENV{HOME}/.syndicator";

    has +configfile => (
        is => 'ro',
        isa => File,
        required => 1,
        default => "$BASE/config.json"
    );

    has sources => (
        is => 'rw',
        isa => UriArray,
        coerce => 1,
        required => 1,
    );

    method run {
        my $db = App::Syndicator::DB->new(
            dsn => "DBI:SQLite:dbname=$BASE/main.db",
            sources => $self->sources,
        );

        my $ui = App::Syndicator::UI->new(
            db => $db,
        );

        $ui->mainloop;
    }
}

1;
__END__

=head1 NAME

App::Syndicator - Curses interface for reading RSS / ATOM feeds.

=head1 SYNOPSIS

 # first run
 $ syndicator --init

 # add sources
 $ vim ~/.syndicator/config.json 

 # run
 $ syndicator 2> errors.log

=head2 EXAMPLE CONFIG

 {
    "sources": [
            "http://blogs.perl.org/atom.xml",
            "http://www.perl.org/pub/atom.xml",
            "http://planet.perl.org/rss20.xml",
            "http://ironman.enlightenedperl.org/atom.xml",
            "http://rss.slashdot.org/Slashdot/slashdot",
            "http://www.theregister.co.uk/software/headlines.atom"
    ]
}

=head1 SEE ALSO

XML::Feed::Aggregator

=head1 AUTHOR

Rob Edwards, E<lt>rge@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Rob Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
