use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Text::Delimited',
    'VERSION_FROM' => 'lib/Text/Delimited.pm',
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/Text/Delimited.pm',
       AUTHOR     => 'Phillip Pollard <bennie@cpan.org>') : ()),
);
