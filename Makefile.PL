use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'          => 'POE::Filter::XML',
	'VERSION_FROM'  => 'POE/Filter/XML.pm',
	'PREREQ_PM'     =>  {
	
		'POE'               => 0,
		'PXR'               => 0,
	}
);
