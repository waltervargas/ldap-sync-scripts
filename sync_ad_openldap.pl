#!/usr/bin/env perl 
use common::sense; 
use lib qw{/root/covetel-ldap-sync/Covetel-LDAP-Sync/lib};

use Covetel::LDAP::Sync;

my $ldap_src = Covetel::LDAP::AD->new({config => 'ad.ini'});
my $ldap_dst = Covetel::LDAP::OpenLDAP->new({config => 'openldap-118.ini'});

my $sync = Covetel::LDAP::Sync->new({
        ldap_src    => $ldap_src,
        ldap_dst    => $ldap_dst,
        config      => 'sync.ini',
        db          => 'sync.db',
#        full_sync   => 1,
        log         => 'sync.log',
        log_level    => 'debug',
});

#$sync->{dry_run} = 1;

print "la fuente es active directory\n" if $sync->_src_is_ad;

my $new_usn;
$new_usn = $sync->run("user");
printf "%s\n", $sync->filter;

$new_usn = $sync->run("group");
printf "%s\n", $sync->filter;

$new_usn = $sync->run("list");
printf "%s\n", $sync->filter;
#$sync->update_usn($new_usn);


 



1;
