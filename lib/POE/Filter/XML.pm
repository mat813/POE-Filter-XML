package POE::Filter::XML;

use strict;
my $parser;
my $parse_method;

our $VERSION = '0.1.1';

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
		require PXR::Parser;
		$parser = 'PXR::Parser';
		$parse_method = 'parse';
	}
}
use POE::Filter::XML::Handler;
use POE::Filter::XML::Meta;

sub new {
	
    my ($class, $buffer, $callback, $handler, $meta) = @_;
    
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
	
	my $self = {};

	my $docstart = sub { $handler->startDocument(@_) };
	my $docend = sub { $handler->endDocument(@_) };
	my $start = sub { $handler->startElement(@_); };
	my $end = sub { $handler->endElement(@_); };
	my $char = sub { $handler->characters(@_); };

	if($parser eq 'PXR::Parser')
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
			'buffer'	=> [],
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
	eval
	{	
		$self->{'parser'}->$parse_method($buffer);
	};

	if($@)
	{
		warn $@;
		return undef;
	}
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

sub get {
    my( $self, $raw )	= @_;

    foreach my $line ( @$raw )
	{
		eval
		{
			$line =~ s/\x{d}\x{a}//g;
			chomp($line);
			$self->{'parser'}->$parse_method( $line );
		};
		
		if($@)
		{
			&{ $self->{'callback'} };
		}
			
    }
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

sub get_one()
{
	my ($self, $raw) = @_;
	my $packets = $self->get($raw);
	push @{$self->{'buffer'}}, @$packets;
	my $packet = shift(@{$self->{'buffer'}});
	my $return = [];
	push(@$return, $packet);
	
	return($return);
}
	

sub put {
    my( $self, $nodes ) = @_;
    
	my $output = [];

    foreach my $node ( @$nodes ) 
	{
		my $cooked = $self->{'meta'}->outfilter(\$node);
		push(@$output, $cooked);
	}
	
    return($output);
}

1;
