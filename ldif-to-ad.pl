#!/usr/bin/env perl
use common::sense;
use Net::LDAP::LDIF;
use Net::LDAP::Entry;
use lib qw{/home/elsanto/git/covetel/covetel-ldap/lib};
use Covetel::LDAP::AD;

my $i = 2000;
my $ldif = Net::LDAP::LDIF->new("output.ldif","r",onerror => 'undef');
my $ldap = Covetel::LDAP::AD->new;

$ldap->bind || die "No pudo conectarse al LDAP";
    
while( not $ldif->eof ){

    unless ( $ldif->error ){
        my $entry = $ldif->read_entry;
        say $i;
        $i--;
        next if $i > 1;
        my $result = $ldap->{server}->add($entry);

        printf "Procesando %s\n", $entry->dn;

        if ($result->is_error){
            say "Error:  " . $entry->dn . ' ' 
            . "\n". $result->code() 
            . "\n". $result->error() 
            . "\n". $result->error_name()
            . "\n". $result->error_desc()
            . "\n". $result->error_text();
        }

    } else {
        printf "Error: %s\n", $ldif->error; 
    }

}
$ldif->done;
