#!/usr/bin/env perl
use common::sense;
use lib qw{/Users/elsanto/git/covetel/covetel-ldap/lib};
use Covetel::LDAP::OpenLDAP;

my $ldap = Covetel::LDAP::OpenLDAP->new({config => 'openldap.ini'});

if ($ldap->bind){
    
    $ldap->create_ou('people', {description => 'Personas'});
    $ldap->create_ou('groups', {description => 'Grupos'});

}
