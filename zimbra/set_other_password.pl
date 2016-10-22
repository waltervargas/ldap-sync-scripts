#!/usr/bin/env perl                                                                       

use common::sense;
use lib qw{/Users/elsanto/git/covetel/covetel-ldap/lib};
use Covetel::LDAP::OpenLDAP;

my $password = 'passwd';

my $ldap = Covetel::LDAP::OpenLDAP->new({config => 'openldap.ini'});

$ldap->bind;


my $resp = $ldap->search({filter => "(objectClass=person)"});

if ($resp->count){
    
    for ($resp->entries){
        if ($ldap->add_other_password($password,$_)){
            printf "Setting Second Password for: %s\n", $_->dn;
        } else {
            say "Someting wrong\n"
        }   

    }   

} else {
    printf "%s", $ldap->{mesg}->error_desc;
}

