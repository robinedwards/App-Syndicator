use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'App::Syndicator',
    VERSION_FROM      => 'lib/App/Syndicator.pm',
    PREREQ_PM         => {
        Config::Any => 0,
        MooseX::Declare => 0,
        JSON => 0,
        MooseX::Types => 0,
        MooseX::Types::URI => 0,
        MooseX::Getopt => 0,
        MooseX::ConfigFromFile => 0,
        XML::Feed => 0,
        HTML::FormatText => 0,
        Term::ANSIColor => 0,
    },
    ($] >= 5.005 ?   
      (ABSTRACT_FROM  => 'lib/App/Syndicator.pm',
       AUTHOR         => 'Rob Edwards <rge@cpan.org>') : ()),
);
