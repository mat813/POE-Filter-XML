package POE::Filter::XML::NS;
{
  $POE::Filter::XML::NS::VERSION = '1.140700';
}

#ABSTRACT: Provides constants that return appropriate namespace strings

use strict;
use warnings;

use constant {
	XMLNS_STREAM => 'http://etherx.jabber.org/streams',
	
	NS_JABBER_CLIENT => 'jabber:client',
	NS_JABBER_COMPONENT => 'http://jabberd.jabberstudio.org/ns/component/1.0',
	NS_JABBER_ACCEPT => 'jabber:component:accept',
	NS_JABBER_CONNECT => 'jabber:component:connect',
	NS_JABBER_DIALBACK => 'jabber:server:dialback',

	NS_JABBER_AUTH => 'jabber:iq:auth',
	NS_JABBER_REGISTER => 'jabber:iq:register',
	NS_JABBER_DISCOINFO => 'http://jabber.org/protocol/disco#info',
	NS_JABBER_DISCOITEMS => 'http://jabber.org/protocol/disco#items',
	NS_JABBER_ROSTER => 'jabber:iq:roster',

	NS_XMPP_SASL => 'urn:ietf:params:xml:ns:xmpp-sasl',
	NS_XMPP_TLS => 'urn:ietf:params:xml:ns:xmpp-tls',
	NS_XMPP_BIND => 'urn:ietf:params:xml:ns:xmpp-bind',
	NS_XMPP_STANZA => 'urn:ietf:params:xml:ns:xmpp-stanzas',
	NS_XMPP_SESSION => 'urn:ietf:params:xml:ns:xmpp-session',
	NS_XMPP_STREAMS	=> 'urn:ietf:params:xml:ns:xmpp-streams',
	NS_XMPP_OTHER => '##other',

	IQ_GET => 'get',
	IQ_SET => 'set',
	IQ_ERROR => 'error',
	IQ_RESULT => 'result',

};

require Exporter;
our @ISA = qw/ Exporter /;

our @EXPORT_OK = qw/ NS_JABBER_CLIENT NS_JABBER_ACCEPT  
	NS_JABBER_CONNECT NS_JABBER_COMPONENT NS_XMPP_SASL
	NS_JABBER_DISCOINFO NS_JABBER_DISCOITEMS
	IQ_GET IQ_SET IQ_ERROR IQ_RESULT NS_JABBER_AUTH NS_JABBER_REGISTER
	NS_DISCOINFO NS_DISCOITEMS XMLNS_STREAM NS_JABBER_ROSTER
	NS_XMPP_STANZA NS_XMPP_OTHER NS_XMPP_SESSION NS_XMPP_BIND NS_XMPP_TLS
	NS_XMPP_STREAMS/;

our %EXPORT_TAGS = (
	JABBER	=> [
		qw/ NS_JABBER_DISCOINFO NS_JABBER_DISCOITEMS NS_JABBER_AUTH 
		NS_JABBER_REGISTER NS_JABBER_CLIENT XMLNS_STREAM
		NS_JABBER_ROSTER NS_JABBER_ACCEPT NS_JABBER_CONNECT 
		NS_JABBER_COMPONENT	NS_XMPP_SASL NS_XMPP_STANZA
		NS_XMPP_TLS NS_XMPP_BIND NS_XMPP_SESSION NS_XMPP_OTHER 
		NS_XMPP_STREAMS/
	],
	IQ		=> [
		qw/ IQ_GET IQ_SET IQ_ERROR IQ_RESULT /
	]);
	
my %seen;
		
push @{$EXPORT_TAGS{'all'}}, 
	grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;

1;



=pod

=head1 NAME

POE::Filter::XML::NS - Provides constants that return appropriate namespace strings

=head1 VERSION

version 1.140700

=head1 SYNOPSIS

use POE::Filter::XML::NS qw/ :JABBER :IQ /;

=head1 DESCRIPTION

POE::Filter::XML::NS provides namespace constants for use within 
POE::Filter::XML::Nodes (or any other representation) that requires namespace
matching. The following export tags are explained below:

=over 4

=item :JABBER

":JABBER" tag will import various useful constants for use within a normal 
Jabber client and component(to reference implementation server) situation.

=item ":IQ"

":IQ" tag imports convenience <iq/> packet types such as set, get, result, and
error

=item ":all"

":all" will import every tag available within the package.

=back

Please reference the source file to know which namespaces are explictly
supported and exported.

=head1 AUTHOR

Nicholas R. Perez <nperez@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Nicholas R. Perez <nperez@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

