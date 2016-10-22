#!/usr/bin/env perl
use common::sense;
use lib qw{/Users/elsanto/git/covetel/covetel-ldap/lib};
use Covetel::LDAP::OpenLDAP;
use Net::LDAP qw(LDAP_CONTROL_TREE_DELETE);

my $ldap = Covetel::LDAP::OpenLDAP->new({config => 'openldap.ini'});

die $ldap->{mesg}->error_text unless $ldap->bind;

my $dn = "ou=personas,dc=pdval,dc=gob,dc=ve";

&clean_tree($dn);


sub clean_tree {
    my $dn = shift;

    my $res = $ldap->{server}->delete($dn, control => {type => LDAP_CONTROL_TREE_DELETE});

    if ($res->is_error){
        say $res->error
        . '\n' . $res->error_name
        . '\n' . $res->error_text
        . '\n' . $res->error_desc;
    } else {
        say "ok!"; 
    }

}
