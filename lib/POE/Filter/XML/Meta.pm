package POE::Filter::XML::Meta;
use strict;
use warnings;

our $VERSION = '0.1';

sub new()
{
	my $class = shift;
	my $self;
	bless(\$self, $class);
	return \$self;
}

sub infilter()
{
	my ($self, $node) = @_; # Note: $node is a reference
	return $self->_default($node, 0);
}

sub outfilter()
{
	my ($self, $node) = @_; # Note: $node is a reference
	return $self->_default($node, 1);
	
}

sub _default()
{
	my ($self, $node, $outbound) = @_;

	if($outbound)
	{
		if(ref($$node) eq 'POE::Filter::XML::Node')
		{
			return ${$node}->to_str();

		} else {

			return $$node;
		}
		
	} else {

		return $$node;
	}
}
1;
