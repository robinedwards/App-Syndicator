use MooseX::Declare;

class App::Syndicator::Types {
    use Moose::Util::TypeConstraints;
    use MooseX::Types::Moose qw/Object ArrayRef Str Int Bool/;
    use MooseX::Types -declare=> [qw(
        Entry_T DateTime_T UriArray View_T Aggregator_T
        Store_T Importer_T PositiveInt File
    )];
    use MooseX::Types::URI 'Uri';
    use MooseX::Types::DateTime 'DateTime';

    subtype Entry_T,
        as Object,
        where {
            $_->isa('XML::Feed::Entry');
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

    subtype File,
        as Str,
        where { -f $_ },
        message {"$_ is not a file" };
    
    subtype View_T,
        as Object,
        where {
            $_->can('display');
        };

    subtype PositiveInt,
        as Int,
        where { 
            $_ > 0;
        };

    class_type Aggregator_T, { class => 'XML::Feed::Aggregator' };
    class_type Store_T, { class => 'App::Syndicator::Store' };
    class_type Importer_T, { class => 'App::Syndicator::Importer' };
}
