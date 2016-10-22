#!/usr/bin/env perl 
use common::sense; 
use lib qw{/Users/elsanto/git/covetel/covetel-ldap-sync/Covetel-LDAP-Sync/lib};
use Covetel::LDAP::Sync;

my $ldap_src = Covetel::LDAP::OpenLDAP->new({config => 'zimbra.ini'});
my $ldap_dst = Covetel::LDAP::OpenLDAP->new({config => 'openldap.ini'});

my $sync = Covetel::LDAP::Sync->new({
        ldap_src    => $ldap_src,
        ldap_dst    => $ldap_dst,
        config      => 'sync.ini',
        db          => 'sync.db',
        log         => 'sync.log',
});

my $filter 
    = "(&(objectClass=zimbraAccount)"
    . "(objectClass=organizationalPerson)"
    . "(zimbraAccountStatus=active)"
    . "(zimbraMailStatus=enabled)"
    . "(!(zimbraIsSystemResource=TRUE))" . ")";



$sync->filter($filter);

my @black_list = &exception;

$sync->black_list(@black_list);

$sync->run("user");

sub exception {                                                                           

    open FH, '<', 'exceptions.txt';                                                           
    my @exceptions = <FH>;
    close FH; 
    
    map { chomp; } @exceptions;

    return @exceptions;

}
