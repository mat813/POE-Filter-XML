use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'          => 'POE::Filter::XML',
	'VERSION_FROM'  => 'lib/POE/Filter/XML.pm',
	'PREREQ_PM'     =>  {
	
		'POE'               => 0,
	}
);
