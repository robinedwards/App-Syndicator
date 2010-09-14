use MooseX::Declare;

class App::Syndicator::Message {
    use MooseX::Types::Moose 'Str';
    use MooseX::Types::URI 'Uri';
    use App::Syndicator::Types ':all';
    use Digest::MD5 'md5_base64';

    has title => (
        is => 'rw',
        coerce => 1,
        isa => MessageTitle_T,
        lazy_build => 1,
        required => 1
    );

    has body => (
        is => 'rw',
        coerce => 1,
        isa => MessageBody_T,
        lazy_build => 1,
        required => 1
    );

    has author => (
        isa => Str,
        is => 'rw',
        required => 1,
        default => 'Unknown'
    );

    has id => (
        isa => Str,
        is => 'rw',
        required => 1,
        lazy_build => 1
    );

    has published => (
        is => 'rw',
        coerce => 1,
        isa => DateTime_T,
        lazy_build => 1,
        required => 1
    );

    has format => (
        is => 'rw',
        isa => Str,
        lazy_build => 1,
        required => 1
    );

    has uri => (
        is => 'rw',
        isa => Uri,
        coerce => 1,
        lazy_build => 1,
        required => 1,
        handles => {link => 'as_string'}
    );

    has base_uri => (
        is => 'rw',
        isa => Uri,
        coerce => 1,
        lazy_build => 1,
        required => 1,
        handles => {base_link => 'as_string'}
    );

    has xml_entry => (
        is => 'rw',
        isa => Entry_T,
    );

    method BUILDARGS(ClassName $class: Entry_T $entry) {
        return $class->next::method({xml_entry=>$entry});
    }

    method BUILD {
        if (my $entry = $self->xml_entry) {
            for my $attr (qw/title format author/) {
                $self->$attr($entry->$attr);
            }

            $self->uri($entry->link);
            $self->base_uri($entry->base_link);

            $self->published(
                $entry->modified | $entry->issued
            );

            (length($entry->content->body) >= length($entry->summary->body))
                ? $self->body($entry->content->body)
                    : $self->content($entry->summary->body);

            $self->id(
                md5_base64(
                    $entry->id,
                    $self->published
                )
            );

            $self->xml_entry(undef);
        }
    }
    
}


1;
