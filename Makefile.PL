
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'XML parsing for the POE framework',
  'AUTHOR' => 'Nicholas R. Perez <nperez@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'POE-Filter-XML',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'POE::Filter::XML',
  'PREREQ_PM' => {
    'Carp' => '0',
    'Exporter' => '0',
    'Moose::Object' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'MooseX::Declare' => '0',
    'MooseX::InsideOut' => '0',
    'MooseX::NonMoose' => '0',
    'MooseX::NonMoose::InsideOut' => '0',
    'MooseX::Types::Moose' => '0',
    'POE::Filter' => '0',
    'Try::Tiny' => '0',
    'XML::LibXML' => '0',
    'XML::LibXML::Element' => '0',
    'XML::SAX::Base' => '0',
    'constant' => '0'
  },
  'VERSION' => '1.102960',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



