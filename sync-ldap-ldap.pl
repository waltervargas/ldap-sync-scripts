#!/usr/bin/env perl 
use common::sense; 
use lib qw{/home/elsanto/git/covetel/covetel-ldap-sync/Covetel-LDAP-Sync/lib};
use Covetel::LDAP::Sync;

my $ldap_dst = Covetel::LDAP::OpenLDAP->new({config => 'openldap.ini'});
my $ldap_src = Covetel::LDAP::AD->new({config => 'ad.ini'});

my $sync = Covetel::LDAP::Sync->new({
        ldap_src    => $ldap_src,
        ldap_dst    => $ldap_dst,
        config      => 'sync.ini',
        db          => 'sync.db',
        log         => 'sync.log',
});


$sync->run("user");
$sync->run("group");

1;
