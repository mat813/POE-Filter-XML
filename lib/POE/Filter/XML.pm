package POE::Filter::XML;
use strict;
use warnings;

our $VERSION = '0.29';

use XML::SAX;
use XML::SAX::ParserFactory;
use POE::Filter::XML::Handler;
use POE::Filter::XML::Meta;
$XML::SAX::ParserPackage = "XML::SAX::Expat::Incremental (0.02)";

sub clone()
{
	my ($self, $buffer, $callback, $handler, $meta) = @_;
	
	return POE::Filter::XML->new($buffer, $callback, $handler, $meta);
}

sub new() 
{
	
	my ($class, $buffer, $callback, $handler, $meta) = @_;
	
	my $self = {};

	if(not defined($buffer))
	{
		$buffer = '';
	}

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
	
	my $parser = XML::SAX::ParserFactory->parser('Handler' => $handler);
	
	$self->{'meta'} = $meta;
	$self->{'handler'} = $handler;
	$self->{'parser'} = $parser;
	$self->{'callback'} = $callback;
	
	eval
	{
		$self->{'parser'}->parse_string($buffer);
	
	}; 
	
	if ($@)
	{
		warn $@;
		&{ $self->{'callback'} }($@);
	}

		
	
	bless($self, $class);
	return $self;
}

sub DESTROY()
{
	my $self = shift;
	
	delete $self->{'meta'};
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

	$self->{'parser'} = XML::SAX::ParserFactory->parser
	(	
		'Handler' => $self->{'handler'}
	);

	delete $self->{'buffer'};
}

sub get_one_start()
{
	my ($self, $raw) = @_;
	if (defined $raw) 
	{
		foreach my $raw_data (@$raw) 
		{
			push
			(
				@{$self->{'buffer'}}, 
				split
				(
					/(?:\015?\012|\012\015?)/s, 
					$raw_data
				)
			);
		}
	}
}

sub get_one()
{
	my ($self) = @_;

	if($self->{'handler'}->finished_nodes())
	{
		my $node = $self->{'handler'}->get_node();
		$node = $self->{'meta'}->infilter($node);
		return [$node];
	
	} else {
		
		for(0..$#{$self->{'buffer'}})
		{
			my $line = shift(@{$self->{'buffer'}});
			
			next unless($line);

			eval
			{
				$line =~ s/\x{d}\x{a}//go;
				$line =~ s/\x{a}\x{d}//go;
				chomp($line);
				$self->{'parser'}->parse_string($line);

			};
			
			if($@)
			{
				warn $@;
				&{ $self->{'callback'} }($@);
			}

			if($self->{'handler'}->finished_nodes())
			{
				my $node = $self->{'handler'}->get_node();
				$node = $self->{'meta'}->infilter($node);
				return [$node];
			}
		}
		return [];
	}
}

sub get()
{
	my ($self,$raw) = @_;

	if (defined $raw) 
	{
		foreach my $raw_data (@$raw) 
		{
		    push
			(
				@{$self->{'buffer'}}, 
				split
				(
					/(?:\015?\012|\012\015?)/s, 
					$raw_data
				)
			);
		}
	}

	if($self->{'handler'}->finished_nodes())
	{
	    my $return = [];
	    
		while(my $node = $self->{'handler'}->get_node())
	    {
			$node = $self->{'meta'}->infilter($node);
			push @$return, $node;
	    }
		
	    return($return);
	
	} else {
	    
		for(0..$#{$self->{'buffer'}})
		{
		    my $line = shift(@{$self->{'buffer'}});
			
		    next unless($line);
		    
		    eval
		    {
				$line =~ s/\x{d}\x{a}//go;
				$line =~ s/\x{a}\x{d}//go;
				chomp($line);
				$self->{'parser'}->parse_string($line);
		    };
		    
		    if($@)
		    {
				warn $@;
				&{ $self->{'callback'} }($@);
		    }
		    
		}
		
	    if($self->{'handler'}->finished_nodes())
	    {		
			my $return = [];
			
			while(my $node = $self->{'handler'}->get_node())
			{
		    	$node = $self->{'meta'}->infilter($node);
		    	push @$return, $node;
			}
		
			return($return);
	    }
	}
}
	
sub put()
{
	my($self, $nodes) = @_;
	
	my $output = [];

	foreach my $node (@$nodes) 
	{
		my $cooked = $self->{'meta'}->outfilter($node);
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
strategy for POE::Wheels that will be dealing with XML streams.

POE::Filter::XML relies upon XML::SAX and XML::SAX::ParserFactory to acquire
a parser for parsing XML. 

The assumed parser is XML::SAX::Expat::Incremental (Need a real push parser)

Default, the Filter will spit out POE::Filter::XML::Nodes because that is 
what the default XML::SAX compliant Handler produces from the stream it is 
given. You are of course encouraged to override the default Handler for your 
own purposes if you feel POE::Filter::XML::Node to be inadequate.

=head1 PUBLIC METHODS

Since POE::Filter::XML follows the POE::Filter API look to POE::Filter for 
documentation. The only method covered here is new()

=over 4 

=item new()

new() accepts a total of four(4) arguments that are all optional: (1) a string
that is XML waiting to be parsed (i.e. xml received from the wheel before the
Filter was instantiated), (2) a coderef to be executed upon a parsing error,
(3) a XML::SAX complient Handler and (4) a meta Filter -- A secondary filter 
for another level of abstraction if desired, for example, say I want to use 
Serialize::XML in conjunction with POE::Filter::XML::Node, each 
POE::Filter::XML::Node would get delivered to the secondary filter where the 
Nodes are returned to XML and that xml interpreted to recreate perl objects.

See POE::Filter::XML::Meta for implementing your own meta Filter.

=back 4

=head1 BUGS AND NOTES

Previous versions relied upon XML::Parser (an expat derivative) or a very poor
pure perl XML parser pulled from XML::Stream. XML::SAX is now the standard and
has greatly simplified development on this project.

=head1 AUTHOR

Copyright (c) 2003, 2004, 2005 Nicholas Perez. 
Released and distributed under the GPL.

=cut
