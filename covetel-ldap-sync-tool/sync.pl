#!/usr/bin/env perl 
use common::sense; 
use lib qw{/root/covetel-ldap/lib};
use lib qw{/root/covetel-ldap-sync/Covetel-LDAP-Sync/lib};

use Covetel::LDAP::Sync;

my $ldap_src = Covetel::LDAP::OpenLDAP->new({config => '/opt/covetel-ldap-sync-tool/zimbra-maqueta.ini'});
my $ldap_dst = Covetel::LDAP::OpenLDAP->new({config => '/opt/covetel-ldap-sync-tool/openldap.ini'});
my $filter;

my $sync = Covetel::LDAP::Sync->new({
        ldap_src    => $ldap_src,
        ldap_dst    => $ldap_dst,
        config      => '/opt/covetel-ldap-sync-tool/sync.ini',
        db          => '/opt/covetel-ldap-sync-tool/sync.db',
        log         => '/opt/covetel-ldap-sync-tool/log/sync.log',
});

$sync->_load_db;

# get the last timestamp 
my $timestamp = $sync->{db}->get("modifyTimestamp");

# filter whitout timestamp
my $filter_full
    = "(&(objectClass=zimbraAccount)"
    . "(objectClass=organizationalPerson)"
    . "(zimbraAccountStatus=active)"
    . "(zimbraMailStatus=enabled)"
    . "(!(zimbraIsSystemResource=TRUE))" . ")";

# if timestamp eq 0 fullsync, else use modifyTimestamp >= $timestamp
if ($timestamp){
	$filter 
    = "(&(objectClass=zimbraAccount)"
    . "(objectClass=organizationalPerson)"
    . "(zimbraAccountStatus=active)"
    . "(zimbraMailStatus=enabled)"
	. "(modifyTimestamp>=$timestamp)"
    . "(!(zimbraIsSystemResource=TRUE))" . ")";
} else {
	$filter = $filter_full; 
}


# Only search and prepare update but not update. 
$sync->{dry_run} = 0;

$sync->filter($filter);

# sync users
$sync->run("user");

# Search for the next timestamp
my $resp = $ldap_src->search({ filter => $filter_full, attrs => 'modifyTimestamp'});

my @timestamps;

if ($resp->count){
	foreach my $entry ($resp->entries){
		push @timestamps, $entry->get_value('modifyTimestamp');
	}
	
	@timestamps = sort {$b <=> $a} @timestamps;

	$sync->{db}->put("modifyTimestamp",$timestamps[0]) if $timestamps[0] > $timestamp;
	
} else {
	die "problem no have timestamp"
}

