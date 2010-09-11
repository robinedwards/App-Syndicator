use MooseX::Declare;

class App::Syndicator::Message {
    use App::Syndicator::Types;
    use Digest::MD5 'md5_base64';

    has title => (
        is => 'ro',
        coerce => 1,
        isa => MessageTitle_T,
        required => 1
    );

    has body => (
        is => 'ro',
        coerce => 1,
        isa => MessageBody_T,
        required => 1
    );

    has author => (
        isa => Str,
        is => 'ro',
        required => 1,
        default => 'Unknown'
    );

    has uid => (
        isa => Str,
        is => 'ro',
        required => 1,
        lazy_build => 1
    );

    has published => (
        is => 'ro',
        coerce => 1,
        isa => DateTime_T,
        required => 1
    );

    has format => (
        is => 'ro',
        isa => Str,
        required => 1
    );

    has link => (
        is => 'ro',
        isa => Uri,
        coerce => 1,
        required => 1
    );

    has base_link => (
        is => 'ro',
        isa => Uri,
        coerce => 1,
        required => 1
    );

    method _build_id {
        $self->id(
            md5_base64(
                $self->id,
                $self->published
            )
        );
    }
}


1;
