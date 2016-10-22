#!/usr/bin/env perl 
use common::sense; 
use lib qw{/home/max/covetel/covetel-ldap-sync/Covetel-LDAP-Sync/lib};
use Covetel::LDAP::Sync;
use Data::Dumper;

my $ldap_src = Covetel::LDAP::AD->new({config => 'ad.ini'});
my $ldap_dst = Covetel::LDAP::OpenLDAP->new({config => 'openldap.ini'});


my $ngroups = 2000; # number of groups to create
my $group_len = 10; #max number of members for each group

my $sync = Covetel::LDAP::Sync->new({
        ldap_src    => $ldap_src,
        ldap_dst    => $ldap_dst,
        config      => 'sync.ini',
        db          => 'sync.db',
        log         => 'sync.log',
});

         
my @users = ("CN=Administrator,CN=Users,DC=example,DC=com,DC=ve", 
"CN=Guest,CN=Users,DC=example,DC=com,DC=ve", 
"CN=SUPPORT_388945a0,CN=Users,DC=example,DC=com,DC=ve") 
           
$sync->{src}->bind;

for (my $i = 0; $i < $ngroups; $i++){
    my $cn = "testgroup".$i;
    my $dn = 'CN='.$cn.',CN=Users,DC=example,DC=com,DC=ve';
    
    my $entry = Net::LDAP::Entry->new ( $dn ,
            "objectClass" => 'group' ,
            cn => $cn ,
    );
    for (my $j = 0; $j < $group_len; $j++){
        my $rand = rand(1000);
        $entry->add(member => $users[$rand]);
    }
    my  $res = $sync->{"src"}->{'server'}->add($entry);

    sleep(1);
    #sleep (60) if $i % 300 == 299;
 
}

1;
