##############################################################################
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; if not, write to the
#  Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#  Boston, MA  02111-1307, USA.
#
#  Copyright (C) 2003 Nicholas Perez
#  Copyright (C) 1998-1999 The Jabber Team http://jabber.org/
#  Original Author Ryan Eatmon in January of 2001
#  Modified for use in PXR  by Nicholas Perez in June of 2003
#
##############################################################################

package POE::Filter::XML::Parser;

use strict;
use warnings;

our $VERSION = '0.1.1';

sub new
{
    my $self = {};

    bless($self);

    my %args;
    while($#_ >= 0) { $args{ lc pop(@_) } = pop(@_); }

    $self->{PARSING} = 0;
    $self->{DOC} = 0;
    $self->{XML} = "";
    $self->{CNAME} = ();
    $self->{CURR} = 0;
	$self->{XMLONHOLD} = "";

    $self->setHandlers(%{$args{handlers}});

    return $self;
}

sub setHandlers
{
    my $self = shift;
    my (%handlers) = @_;

    foreach my $handler (keys(%handlers))
    {
        $self->{HANDLER}->{$handler} = $handlers{$handler};
    }
}


sub parse
{
    my $self = shift;
    my $xml = shift;

    return unless defined($xml);
    return if ($xml eq "");

    if ($self->{XMLONHOLD} ne "")
    {
        $self->{XML} = $self->{XMLONHOLD};
        $self->{XMLONHOLD} = "";
    }

    # XXX change this to not use regex?
    while($xml =~ s/<\!--.*?-->//gso) {}

    $self->{XML} .= $xml;

    return if ($self->{PARSING} == 1);

    $self->{PARSING} = 1;

    if(!$self->{DOC} == 1)
    {
        my $start = index($self->{XML},"<");

        if ((substr($self->{XML},$start,3) eq "<?x") ||
            (substr($self->{XML},$start,3) eq "<?X"))
        {
            my $close = index($self->{XML},"?>");
            if ($close == -1)
            {
                $self->{PARSING} = 0;
                return;
            }
            $self->{XML} = substr($self->{XML},$close+2,length($self->{XML})-$close-2);
        }

        &{$self->{HANDLER}->{startDocument}}($self);
        $self->{DOC} = 1;
    }

    while(1)
    {
        if (length($self->{XML}) == 0)
        {
            $self->{PARSING} = 0;
            return;
        }
        my $eclose = -1;
        $eclose = index($self->{XML},"</".$self->{CNAME}->[$self->{CURR}].">")
            if ($#{$self->{CNAME}} > -1);

        if ($eclose == 0)
        {
            $self->{XML} = substr($self->{XML},length($self->{CNAME}->[$self->{CURR}])+3,length($self->{XML})-length($self->{CNAME}->[$self->{CURR}])-3);

            &{$self->{HANDLER}->{endElement}}($self,$self->{CNAME}->[$self->{CURR}]);

            $self->{CURR}--;
            if ($self->{CURR} == 0)
            {
                $self->{DOC} = 0;
                $self->{PARSING} = 0;
                &{$self->{HANDLER}->{endDocument}}($self);
                return;
            }
            next;
		}
			
        my $estart = index($self->{XML},"<");
        my $cdatastart = index($self->{XML},"<![CDATA[");
        if (($estart == 0) && ($cdatastart != 0))
        {
            my $close = index($self->{XML},">");
            if ($close == -1)
            {
                $self->{PARSING} = 0;
                return;
            }
            my $empty = (substr($self->{XML},$close-1,1) eq "/");
            my $starttag = substr($self->{XML},1,$close-($empty ? 2 : 1));
            my $nextspace = index($starttag," ");
            my $attribs;
            my $name;
            if ($nextspace != -1)
            {
                $name = substr($starttag,0,$nextspace);
                $attribs = substr($starttag,$nextspace+1,length($starttag)-$nextspace-1);
            }
            else
            {
                $name = $starttag;
            }

            my %attribs = $self->attribution($attribs);
            &{$self->{HANDLER}->{startElement}}($self,$name,%attribs);

            if($empty == 1)
            {
                &{$self->{HANDLER}->{endElement}}($self,$name);
            }
            else
            {
                $self->{CURR}++;
                $self->{CNAME}->[$self->{CURR}] = $name;
            }
    
            $self->{XML} = substr($self->{XML},$close+1,length($self->{XML})-$close-1);
            next;
        }

        if ($cdatastart == 0)
        {
            my $cdataclose = index($self->{XML},"]]>");
            if ($cdataclose == -1)
            {
                $self->{PARSING} = 0;
                return;
            }
            
            &{$self->{HANDLER}->{characters}}($self,substr($self->{XML},9,$cdataclose-9));
            
            $self->{XML} = substr($self->{XML},$cdataclose+3,length($self->{XML})-$cdataclose-3);
            next;
         }

        if ($estart == -1)
        {
            $self->{XMLONHOLD} = $self->{XML};
            $self->{XML} = "";
        }
        elsif (($cdatastart == -1) || ($cdatastart > $estart))
        {
            &{$self->{HANDLER}->{characters}}($self,$self->entityCheck(substr($self->{XML},0,$estart)));
            $self->{XML} = substr($self->{XML},$estart,length($self->{XML})-$estart);
        }
    }
}


sub attribution
{
    my $self = shift;
    my $str = shift;

    $str = "" unless defined($str);

    my %attribs;

    while(1)
    {
        my $eq = index($str,"=");
        if((length($str) == 0) || ($eq == -1))
        {
            return %attribs;
        }

        my $ids;
        my $id;
        my $id1 = index($str,"\'");
        my $id2 = index($str,"\"");
        if((($id1 < $id2) && ($id1 != -1)) || ($id2 == -1))
        {
            $ids = $id1;
            $id = "\'";
        }
        if((($id2 < $id1) && ($id1 == -1)) || ($id2 != -1))
        {
            $ids = $id2;
            $id = "\"";
        }

        my $nextid = index($str,$id,$ids+1);
        my $val = substr($str,$ids+1,$nextid-$ids-1);
        my $key = substr($str,0,$eq);

        while($key =~ s/\s//) {}

        $attribs{$key} = $self->entityCheck($val);
        $str = substr($str,$nextid+1,length($str)-$nextid-1);
    }

    return %attribs;
}

sub entityCheck
{
    my $self = shift;
    my $str = shift;

    while($str =~ s/\&lt\;/\</o) {}
    while($str =~ s/\&gt\;/\>/o) {}
    while($str =~ s/\&quot\;/\"/o) {}
    while($str =~ s/\&apos\;/\'/o) {}
    while($str =~ s/\&amp\;/\&/o) {}

    return $str;
}

1;

__END__

=pod

=head1 NAME

 POE::Filter::XML::Parser - Pure Perl SAX XML Push Parser

=head1 SYNOPSIS

 use POE::Filter::XML::Parser;

 my $parser = PXR::Parser->new(
                  'Handlers' => {
                      'startDocument' => \&start_doc,
                      'endDocument'   => \&end_doc,
                      'startElement'  => \&start_element,
                      'endElement'    => \&end_element,
                      'characters'    => \&characters,
                  }
              );
              
 $parser->parse($data);

 $parser->setHandlers('startDocument' => \&different_start);

=head1 DESCRIPTION
 
 A simple, fast, efficient pure perl sax xml parser.

=head1 BUGS AND NOTES

This Parser was blatantly ripped and modified from XML::Stream::Parser because
it was the only pure perl parser simple and speedy enough to be included by
default in various other things such as PXR or PoCo::Jabber. Just note that
there is no recovering or detecting XML malformedness. So if you feed this
little pet something non-tasty, you are in for a surprise (mainly memory
leaking everywhere, and other things like gnawing on furniture). That is the
trade off for its speed. In situtations where you B<know> you are not going to
get malformed XML such as a connection to a jabber server (or other XML
pushing entities) then this parser is ideal. Currently, the speed difference
between this parser and XML::Parser::Expat are about 30 percent in favor of
XML::Parser::Expat (which says alot of the speed of this pure perl 
implementation).

Thanks to Ryan Eatmon for writing and releasing this code. It has been a boon
to those of us that really appreciate a simple small solution.

=head1 AUTHOR

 Copyright (C) 2003 Nicholas Perez
 Copyright (C) 1998-1999 The Jabber Team http://jabber.org/
 Original Author Ryan Eatmon in January of 2001
 Modified for use in PXR by Nicholas Perez in June of 2003
 Released and distributed under the LGPL.

=cut

