use MooseX::Declare;

class App::Syndicator::Types {
    use Moose::Util::TypeConstraints;
    use MooseX::Types::Moose qw/Object ArrayRef Str Int/;
    use MooseX::Types -declare=> [qw(
        Entry_T DateTime_T UriArray View_T Aggregator_T
    )];
    use MooseX::Types::URI 'Uri';
    use MooseX::Types::DateTime 'DateTime';

    subtype Entry_T,
        as Object,
        where {
            ref($_) =~ /Entry/
                and
            $_->can(qw/issued
                modified
                title
                summary
                content
                /);
        },
        message {"expecting Entry object"};
    
    subtype UriArray,
        as ArrayRef[Uri];
        coerce UriArray,
        from ArrayRef[Str],
        via sub {
            [ map { Uri->coerce($_) } @{$_[0]} ];
        };

    subtype DateTime_T,
        as DateTime;
    
    subtype View_T,
        as Object,
        where {
            $_->can('display');
        };

    class_type Aggregator_T, { class => 'XML::Feed::Aggregator' };
}
