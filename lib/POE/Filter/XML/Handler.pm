package POE::Filter::XML::Handler;
use POE::Preprocessor;
const XNode POE::Filter::XML::Node

use strict;
use warnings;
use POE::Filter::XML::Node;

our $VERSION = '0.1';

sub new()
{
	my ($class) = @_;
	my $self = {
		
		'depth'		=> -1,
		'currnode'	=> undef,
		'finished'	=> [],
		'parents'	=> [],
	};

	bless $self, $class;
	return $self;
}

sub reset()
{
	my $self = shift;

	$self->{'currnode'} = undef;
	$self->{'finished'} = [];
	$self->{'parents'} = [];
	$self->{'depth'} = -1;
}

sub startDocument() { }
sub endDocument() { }

sub startElement() 
{
	my ($self, $expat, $tag, %attr ) = @_;
	
	if($self->{'depth'} == -1) 
	{
		#start of a document: make and return the tag
		my $start = XNode->new($tag)->stream_start(1);
		$start->attr($_, $attr{$_}) foreach keys %attr;
		push(@{$self->{'finished'}}, $start);
		$self->{'depth'} = 0;
		return;

	} else {
		$self->{'depth'} += 1;

		# Top level fragment
		if($self->{'depth'} == 1)
		{
			$self->{'currnode'} = XNode->new($tag);
			$self->{'currnode'}->attr($_, $attr{$_}) foreach keys %attr;
			push(@{$self->{'parents'}}, $self->{'currnode'});
		
		} else {
		    
			# Some node within a fragment
			my $kid = $self->{'currnode'}->insert_tag($tag);
			$kid->attr($_, $attr{$_}) foreach keys %attr;
			push(@{$self->{'parents'}}, $self->{'currnode'});
			$self->{'currnode'} = $kid;
		}
	}
}

sub endElement()
{
	my ($self, $expat, $tag ) = @_;
	
	if($self->{'depth'} == 0)
	{
		# gracefully deal with ending document tag
		# and maybe send it off? 
		# could be used to signal reset()?
		my $end = XNode->new($tag)->stream_end(1);
		push(@{$self->{'finished'}}, $end);
	} 
	elsif($self->{'depth'} == 1)
	{
		push(@{$self->{'finished'}}, $self->{'currnode'});
		delete $self->{'currnode'};
		pop(@{$self->{'parents'}});
	
	} else {
		$self->{'currnode'} = pop(@{$self->{'parents'}});
	}

	--$self->{'depth'};
}

sub characters() 
{
	my($self, $expat, $data ) = @_;
	
	if($self->{'depth'} == 0)
	{
		return;
	}
	
	my $data2 = $self->{'currnode'}->data() . $data;
	$self->{'currnode'}->data($data2);
	
}

sub get_node()
{
	my $self = shift;
	return shift(@{$self->{'finished'}});
}

sub finished_nodes()
{
	my $self = shift;
	return scalar(@{$self->{'finished'}})
}

1;
