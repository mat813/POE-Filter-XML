package POE::Filter::XML::Handler;

use strict;
use warnings;
use PXR::Node;

our $VERSION = '0.1';

sub new()
{
	my $class = shift;
	my $self = {
		
		depth		=> 0,
		currnode	=> undef,
		streamerror => undef,
		finished	=> []
	};

	bless $self, $class;
	return $self;
}

sub DESTROY()
{
	my $self = shift;
}

sub startDocument() { }
sub endDocument() { }

sub startElement() 
{
	my ($self, $expat, $tag, %attr ) = @_;

	if( $tag eq "stream:stream" ) 
	{
		return;

	} else {
		$self->{'depth'} += 1;

		# Top level fragment
		if( $self->{'depth'} == 1 ) 
		{
			# Not an error = create the node
			$self->{'currnode'} = PXR::Node->new( $tag );
			$self->{'currnode'}->attr( $_, $attr{$_} ) foreach keys %attr;
		
		} else {
		
			# Some node within a fragment
			my $kid = $self->{'currnode'}->insert_tag( $tag );
			$kid->attr( $_, $attr{$_} ) foreach keys %attr;
			$self->{'currnode'} = $kid;
		}
	}
}

sub endElement()
{
	my ($self, $expat, $tag ) = @_;

	return [] if $self->{'stream:error'};

	if( $self->{'depth'} == 1 )
	{
		push(@{$self->{'finished'}}, $self->{'currnode'});
		delete $self->{'currnode'};
		--$self->{'depth'};
		
	} else {
	
		$self->{'currnode'} = $self->{'currnode'}->parent();
		--$self->{'depth'};
	}

}

sub characters() 
{
	my($self, $expat, $data ) = @_;

	if($self->{'currnode'}->name() eq 'stream:stream')
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
	if(scalar(@{$self->{'finished'}}))
	{
		return 1;

	} else {
	
		return 0;
	}
}

1;
