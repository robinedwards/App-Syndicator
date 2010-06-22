package App::Syndicator;
use MooseX::Declare;

our $VERSION = '0.01';

class App::Syndicator with (MooseX::Getopt::Dashes, App::Syndicator::Config) {
    use Data::Dumper;

    has +configfile => (
        is => 'ro',
        required => 1,
        isa => 'Str',
        default => sub { "$ENV{HOME}/.syndicator"},
    );

    method run {
        warn Data::Dumper $self;
    }
}



1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

App::Syndicator - Perl extension for blah blah blah

=head1 SYNOPSIS

  use App::Syndicator;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for App::Syndicator, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Rob Edwards, E<lt>robin.ge@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Rob Edwards

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
