package POE::Filter::XML;

use strict;
my $parser;
my $parse_method;

our $VERSION = '0.21';

BEGIN
{
	eval
	{
		require XML::Parser;
		$parser = 'XML::Parser';
		$parse_method = 'parse_more';
	};
	if($@)
	{
		require POE::Filter::XML::Parser;
		$parser = 'POE::Filter::XML::Parser';
		$parse_method = 'parse';
	}
}
use POE::Filter::XML::Handler;
use POE::Filter::XML::Meta;

sub clone()
{
	my ($self, $buffer, $callback, $handler, $meta) = @_;
	
	return POE::Filter::XML->new($buffer, $callback, $handler, $meta);
}


sub new() 
{
	
	my ($class, $buffer, $callback, $handler, $meta) = @_;
	
	my $self = {};

	if(not defined($meta))
	{
		$meta = POE::Filter::XML::Meta->new();
	}
	if(not defined($callback))
	{
		$callback = sub{};
	}
	if(not defined($handler))
	{
		$handler = POE::Filter::XML::Handler->new();
	}
	
	my $docstart = sub { $handler->startDocument(@_); };
	my $docend = sub { $handler->endDocument(@_); };
	my $start = sub { $handler->startElement(@_); };
	my $end = sub { $handler->endElement(@_); };
	my $char = sub { $handler->characters(@_); };

	if($parser eq 'POE::Filter::XML::Parser')
	{
		$self = {
			'parser' => $parser->new(
				'Handlers' => {
				'startDocument'	=> $docstart,
				'endDocument'	=> $docend,
				'startElement'	=> $start,
				'endElement'	=> $end,
				'characters'	=> $char,
			   }
			),
		
			'callback'	=> $callback,
			'handler'	=> $handler,
			'buffer'	=> [$buffer],
			'start'		=> $start,
			'end'		=> $end,
			'char'		=> $char,
			'docstart'	=> $docstart,
			'docend'	=> $docend,
			'meta'		=> $meta,
		 };
		 
	} elsif($parser eq 'XML::Parser') {

		$self = {
			'parser' => $parser->new(
				'Handlers' => {
					'Init'	=> $docstart,
					'Final'	=> $docend,
					'Start' => $start,
					'End'   => $end,
					'Char'  => $char,
				}
			)->parse_start(),

			'callback'  => $callback,
			'handler'   => $handler,
			'buffer'    => [],
			'docstart'	=> $docstart,
			'docend'	=> $docend,
			'start'     => $start,
			'end'       => $end,
			'char'      => $char,
			'meta'      => $meta,
		};
	}

	bless($self, $class);
	return $self;
}

sub DESTROY()
{
	my $self = shift;

	delete $self->{'buffer'};
	delete $self->{'callback'};
	delete $self->{'meta'};
	
	delete $self->{'start'};
	delete $self->{'end'};
	delete $self->{'char'};
	delete $self->{'docstart'};
	delete $self->{'docend'};
	
	$self->{'parser'}->release() if $parser eq 'XML::Parser';
	delete $self->{'parser'};
	delete $self->{'handler'};
}

sub reset()
{
	my ($self, $callback, $handler, $meta) = @_;

	if(defined($callback))
	{
		$self->{'callback'} = $callback;
	
	} else {

		delete $self->{'callback'};
	}

	if(defined($handler))
	{
		$self->{'handler'} = $handler;

	} else {

		$self->{'handler'}->reset();
	}

	if(defined($meta))
	{
		$self->{'meta'} = $meta;
	}

	if($parser eq 'XML::Parser')
	{
		$self->{'parser'}->release();
		undef $self->{'parser'};
		$self->{'parser'} = $parser->new
		(
			'Handlers' =>
			{
				'Init'	=> $self->{'docstart'},
				'Final'	=> $self->{'docend'},
				'Start' => $self->{'start'},
				'End'   => $self->{'end'},
				'Char'  => $self->{'char'},
			}
		)->parse_start();
	
	} else { 

		$self->{'parser'} = $parser->new
		(
			'Handlers' => 
			{
				'startDocument' => $self->{'docstart'},
				'endDocument'   => $self->{'docend'},
				'startElement'  => $self->{'start'},
				'endElement'	=> $self->{'end'},
				'characters'	=> $self->{'char'},
			}
		),
	}
	
	delete $self->{'buffer'};
}

sub get() 
{
	my($self, $raw)	= @_;

	push (@{$self->{'buffer'}}, @$raw) if (defined $raw);
	$self->do_parse;
	if($self->{'handler'}->finished_nodes())
	{
		my $return = [];
		while(my $node = $self->{'handler'}->get_node())
		{
			$node = $self->{'meta'}->infilter(\$node);
			push @$return, $node;
		}

		return($return);
		
	} else {
	
		return [];
	}
}

sub get_one_start {
	my ($self, $raw) = @_;
	if (defined $raw) {
		foreach my $raw_data (@$raw) {
			push (@{$self->{'buffer'}}, split (/(?:\015?\012|\012\015?)/s, $raw_data));
		}
	}
}

sub get_one()
{
	my ($self) = @_;

	$self->do_parse(1);

	if($self->{'handler'}->finished_nodes())
	{
		my $node = $self->{'handler'}->get_node();
		$node = $self->{'meta'}->infilter(\$node);
		return [$node];

	} else {

		return [];
	}
}
	
sub do_parse {
	my ($self, $lazy) = @_;

	unless($self->{'handler'}->finished_nodes())
	{
		while (my $line = shift @{$self->{'buffer'}})
		{
			eval
			{
				$line =~ s/\x{d}\x{a}//go;
				chomp($line);
				$self->{'parser'}->$parse_method($line);
			};
		
			if($@)
			{
				warn $@;
				&{ $self->{'callback'} }($@);
			}

			last if($lazy and $self->{'handler'}->finished_nodes());
			
		}
	}
}

sub put {
	my($self, $nodes) = @_;
	
	my $output = [];

	foreach my $node (@$nodes) 
	{
		my $cooked = $self->{'meta'}->outfilter(\$node);
		push(@$output, $cooked);
	}
	
	return($output);
}

1;

__END__

=pod

=head1 NAME

POE::Filter::XML - A POE Filter for parsing XML

=head1 SYSNOPSIS

 use POE::Filter::XML;
 my $filter = POE::Filter::XML->new();

 my $wheel = POE::Wheel:ReadWrite->new(
 	Filter		=> $filter,
	InputEvent	=> 'input_event',
 );

=head1 DESCRIPTION

POE::Filter::XML provides POE with a completely encapsulated XML parsing 
strategy for POE::Wheels that will be dealing with XML streams. By default
the filter will attempt to use XML::Parser as its foundation for xml parsing. 
Otherwise it will depend upon a pure perl SAX parser included 
(POE::Filter::XML::Parser).

Default, the Filter will spit out POE::Filter::XML::Nodes because that is 
what the default Handler produces from the stream it is given. You are of 
course encouraged to override the default Handler for your own purposes 
if you feel POE::Filter::XML::Node to be inadequate.

=head1 PUBLIC METHODS

Since POE::Filter::XML follows the POE::Filter API look to POE::Filter for 
documentation. The only method covered here is new()

=over 4 

=item new()

new() accepts a total of four(4) arguments that are all optional: (1) a string
that is XML waiting to be parsed (i.e. xml received from the wheel before the
Filter was instantiated), (2) a coderef to be executed upon a parsing error,
(3) a SAX Handler that implements the methods 'startDocument', 'endDocument',
'startElement', 'endElement', and 'characters' (See POE::Filter::XML::Handler
for further information on creating your own SAX Handler), and (4) a meta
Filter -- A secondary filter for another level of abstraction if desired, for
example, say I want to use Serialize::XML in conjunction with 
POE::Filter::XML::Node, each POE::Filter::XML::Node would get delivered to the
secondary filter where the Nodes are returned to XML and that xml interpreted
to recreate perl objects.

See POE::Filter::XML::Meta for implementing your own meta Filter.

=back 4

=head1 BUGS AND NOTES

Documentation for this sub project is as clear as mud.

If all else fails, use the source.

=head1 AUTHOR

Copyright (c) 2003 Nicholas Perez. Released and distributed under the GPL.

=cut
