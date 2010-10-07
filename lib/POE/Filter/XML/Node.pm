package POE::Filter::XML::Node;
BEGIN {
  $POE::Filter::XML::Node::VERSION = '1.102800';
}

#ABSTRACT: A XML::LibXML::Element subclass that adds streaming semantics

use MooseX::Declare;


class POE::Filter::XML::Node {
    use MooseX::NonMoose::InsideOut;
    extends 'XML::LibXML::Element';

    use XML::LibXML(':libxml');
    use MooseX::Types::Moose(':all');


    has stream_start => (is => 'ro', writer => '_set_stream_start', isa => Bool, default => 0);
    has stream_end => (is => 'ro', writer => '_set_stream_end', isa => Bool, default => 0);


    method BUILDARGS(ClassName $class: $name) {

        #only a name should be passed
        return { name => $name };
    }


    override cloneNode(Bool $deep) {
        
        my $clone = super();
        
        bless($clone, $self->meta->name());
        
        $clone->_set_stream_start($self->stream_start());
        $clone->_set_stream_end($self->stream_end());
        
        return $clone;
    }

    override getChildrenByTagName(Str $name) {

        return (map { bless($_, $self->meta->name()) } @{ super() });
    }

    override getChildrenByTagNameNS(Str $nsURI, $localname) {

        return (map { bless($_, $self->meta->name()) } @{ super() });
    }

    override getChildrenByLocalName(Str $localname) {
        
        return (map { bless($_, $self->meta->name()) } @{ super() });
    }
    
    override getElementsByTagName(Str $name) {

        return (map { bless($_, $self->meta->name()) } @{ super() });
    }

    override getElementsByTagNameNS(Str $nsURI, $localname) {

        return (map { bless($_, $self->meta->name()) } @{ super() });
    }

    override getElementsByLocalName(Str $localname) {
        
        return (map { bless($_, $self->meta->name()) } @{ super() });
    }
    

    override toString(Bool $formatted?) returns (Str) {

        if($self->stream_start())
        {
            my $string = '<';
            $string .= $self->nodeName();
            foreach my $attr ($self->attributes())
            {
                $string .= sprintf(' %s="%s"', $attr->nodeName(), $attr->value());
            }
            $string .= '>';
            return $string;
        }
        elsif ($self->stream_end())
        {
            return sprintf('</%s>', $self->nodeName()); 
        }
        else
        {
            return super();
        }
    }


    method setAttributes(ArrayRef $array) {

        for(my $i = 0; $i < scalar(@$array); $i++)
        {
            if($array->[$i] eq 'xmlns')
            {
                $self->setNamespace($array->[++$i], '', 0);
            }
            else
            {
                $self->setAttribute($array->[$i], $array->[++$i]);
            }
        }
    }


    method getAttributes() returns (HashRef) {

        my $attributes = {};

        foreach my $attrib ($self->attributes())
        {
            if($attrib->nodeType == XML_ATTRIBUTE_NODE)
            {
                $attributes->{$attrib->nodeName()} = $attrib->value();
            }
        }

        return $attributes;
    }


    method getSingleChildByTagName(Str $name) returns (Maybe[POE::Filter::XML::Node]) {

        my $node = ($self->getChildrenByTagName($name))[0];
        return undef if not defined($node);
        return $node;
    }


    method getChildrenHash() returns (HashRef) {

        my $children = {};

        foreach my $child ($self->getChildrenByTagName("*"))
        {
            my $name = $child->nodeName();
            
            if(!exists($children->{$name}))
            {
                $children->{$name} = [];
            }
            
            push(@{$children->{$name}}, $child);
        }

        return $children;
    }
}



=pod

=head1 NAME

POE::Filter::XML::Node - A XML::LibXML::Element subclass that adds streaming semantics

=head1 VERSION

version 1.102800

=head1 SYNOPSIS

    use POE::Filter::XML::Node;

    my $node = POE::Filter::XML::Node->new('iq');

    $node->setAttributes(
        ['to', 'foo@other', 
        'from', 'bar@other',
        'type', 'get']
    );

    my $query = $node->addNewChild('jabber:iq:foo', 'query');

    $query->appendTextChild('foo_tag', 'bar');

    say $node->toString();

    -- 

    (newlines and tabs for example only)

    <iq to='foo@other' from='bar@other' type='get'>
        <query xmlns='jabber:iq:foo'>
            <foo_tag>bar</foo_tag>
        </query>
    </iq>

=head1 DESCRIPTION

POE::Filter::XML::Node is a XML::LibXML::Element subclass that aims to provide
a few extra convenience methods and light integration into a streaming context.

This module can be used to create arbitrarily complex XML data structures that
know how to stringify themselves.

=head1 PUBLIC_ATTRIBUTES

=head2 stream_[start|end]

    is: ro, isa: Bool, default: false

These two attributes define behaviors to toString() for the node. In the case
of stream_start, this means dropping all children and merely leaving the tag
unterminated (eg. <start>). For stream_end, it will drop any children and treat
the tag like a terminator (eg. </end>).

Each attribute has a private writer ('_set_stream_[start|end]') if it necessary
to manipulate these attributes post construction.

=head1 PUBLIC_METHODS

=head2 override cloneNode

    (Bool $deep)

cloneNode is overriden to carry forward the stream_[end|start] attributes

=head2 override toString

    (Bool $formatted)

toString was overridden to provide special stringification semantics for when
stream_start or stream_end are boolean true. 

=head2 setAttributes

    (ArrayRef $array_of_tuples)

setAttributes() accepts a single arguement: an array reference. Basically you
pair up all the attributes you want to be into the node (ie. [attrib, value])
and this method will process them using setAttribute(). This is just a 
convenience method.

If one of the attributes is 'xmlns', setNamespace() will be called with the 
value used as the $nsURI argument, with no prefix, and not activated.

 eg. 
 ['xmlns', 'http://foo']
        |
        V
 setNamespace($value, '', 0)
        |
        V
 <node xmlns="http://foo"/>

=head2 getAttributes

    returns (HashRef)

This method returns all of the attribute nodes on the Element (filtering out 
namespace declarations) as a HashRef.

=head2 getFirstChildByTagName(Str $name)

    returns (Maybe[POE::Filter::XML::Node])

This is a convenience method that basically does:
 (getChildrenByTagName($name))[0]

=head2 getChildrenHash

    returns (HashRef)

getChildrenHash() returns a hash reference to all the children of that node.
Each key in the hash will be node name, and each value will be an array
reference with all of the children with that name. 

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

