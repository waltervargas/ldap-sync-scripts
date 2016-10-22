#!/usr/bin/env perl 
use common::sense; 
use lib qw{/root/covetel-ldap/lib};

use Covetel::LDAP;
use Covetel::LDAP::OpenLDAP;

my @timestamps;

my $ldap = Covetel::LDAP::OpenLDAP->new({config => '/opt/covetel-ldap-sync-tool/zimbra-maqueta.ini'});

die "Bind error " unless $ldap->bind;

my $resp = $ldap->search({ filter => 'objectClass=person', attrs => 'modifyTimestamp'});

if ($resp->count){
	foreach my $entry ($resp->entries){
		push @timestamps, $entry->get_value('modifyTimestamp');
	}
}

@timestamps = sort {$b <=> $a} @timestamps;

printf "%s\n", $timestamps[0];
