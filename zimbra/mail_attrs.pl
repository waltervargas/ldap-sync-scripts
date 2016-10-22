#!/usr/bin/env perl
use common::sense;
use lib qw{/Users/elsanto/git/covetel/covetel-ldap/lib};
use Covetel::LDAP::OpenLDAP;


my $ldap = Covetel::LDAP::OpenLDAP->new({config => 'openldap.ini'});

my $attrs_to_add;

$attrs_to_add->{mailHost} = '192.168.22.4';
$attrs_to_add->{mailQuotaSize} = '2048'; # Expresado en Megas





if ($ldap->bind){
    
        my $result = $ldap->search(
            {
                base   => $ldap->base_people,
                scope  => "sub",
                filter => "(objectClass=person)"
            }
        );
        
        if ($result->count > 0){
            for my $entry ($result->entries){
                my @objectclass = $entry->get_value('objectClass');
    
                push @objectclass, "top" unless grep {/top/} @objectclass; 
                push @objectclass, "qmailUser" unless grep {/qmailUser/} @objectclass; 
                
                my @attrs = $entry->attributes( nooptions => 1);

                foreach my $attr (keys %{$attrs_to_add}){
                   $entry->add( $attr => $attrs_to_add->{$attr} ) unless grep {/$attr/} @attrs;
                }

                $entry->replace(
                    objectClass => [ @objectclass ],
                );

                my $resp = $entry->update($ldap->{server});

                if ($resp->is_error){
                    say $resp->error
                    . '\n' . $resp->error_name
                    . '\n' . $resp->error_text
                    . '\n' . $resp->error_desc;
                
                } else {
                    printf "Actualizando la entrada %s\n", $entry->dn;
                }
            }
        }
}
