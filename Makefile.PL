use ExtUtils::MakeMaker;

eval { require ExtUtils::AutoInstall };

if ($@ || $ExtUtils::AutoInstall::VERSION < 0.32) 
{
	warn
	(
		"\n",
		"==================================================================\n",
		"\n",
		"PFX's installer magic requires ExtUtils::AutoInstall. PFX comes\n",
		"with an older version, but it will not be installed.	You should\n",
		"install the most recent ExtUtils::AutoInstall at your convenience.\n",
		"\n",
		"==================================================================\n",
		"\n",
	);
	require lib; lib->import('./install');
	require './install/ExtUtils/AutoInstall.pm';
}

ExtUtils::AutoInstall->import
(
	-version => '0.40',
	-core => 
	[
		'POE' => '0.28_02', 
		'Scalar::Util' => '1.14', 
		'XML::SAX' => '0.12',
		'XML::SAX::Expat::Incremental' => '0.02',
	],
);


WriteMakefile
(
	'NAME' => 'POE::Filter::XML',
	'VERSION_FROM' => 'lib/POE/Filter/XML.pm',
	'PREREQ_PM' => 
	{
		'POE' => '0.28_02',
		'Scalar::Util' => '1.14',
		'XML::SAX' => '0.12',
		'XML::SAX::Expat::Incremental' => '0.02',
	},
);
