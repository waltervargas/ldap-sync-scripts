#!/usr/bin/env perl
use common::sense;
use lib qw{/Users/elsanto/git/covetel/covetel-ldap/lib};
use Covetel::LDAP::AD;
use Covetel::LDAP::OpenLDAP;
use DBM::Deep;

my $db = DBM::Deep->new(
    file => "sync.db",
    locking => 1,
    autoflush => 0,
    pack_size => 'small',
);

sub get_high_usn;
sub store_high_usn;
sub fetch_high_usn;
sub base_people;
sub get_rdn;
sub black_list;

my $ad = Covetel::LDAP::AD->new({config => 'ad.ini'});
my $openldap = Covetel::LDAP::OpenLDAP->new({config => 'openldap.ini'});
my $config_sync = Config::Any::INI->load("sync.ini");

my $config = $ad->{config};
my $base = base_people;

if ($ad->bind && $openldap->bind) {

    # Fetch last usn saved.
    my $usn = fetch_high_usn;

    say $usn;

    # Preparing the filter
#    my $filter =    '(&(|(objectClass=person)(objectClass=group))'.
#                    "(uSNChanged>=$usn)".
#                    "(&(!(sAMAccountType=536870912)))".
#                    "(!(isCriticalSystemObject=TRUE))".
#                    ')';
    
    my $filter =    '(&(|(objectClass=person))'.
                    "(uSNChanged>=$usn)".
                    "(&(!(sAMAccountType=536870912)))".
                    "(!(isCriticalSystemObject=TRUE))".
                    ')';
    
    # Perform search 
    my $result = $ad->search(
        {
            base   => $base,
            scope  => "sub",
            filter => $filter
        }
    );

    if ($result->count > 0){
        # my $entry = $result->shift_entry;
        # $entry->dump();
        for my $entry ($result->entries){
            next if black_list $entry;
            my $entry = prepare_entry($entry,'user');
            my $mesg = $entry->update($openldap->{ldap});
            if ($mesg->is_error) {
                die $mesg->error
                    . "\n" . $mesg->code
                    . "\n" . $mesg->error_name
                    . "\n" . $mesg->error_text
                    . "\n" . $mesg->error_desc;
            } else {
                say "sync " . $entry->dn;
            }
        }
    }

    my $new_usn = get_high_usn $ad->{server};  
    say $new_usn;

    if ($new_usn > $usn){
        store_high_usn $new_usn;
    }

} else {
  say $ad->{mesg}->error_text() if $ad->{mesg}->is_error();
  say $openldap->{mesg}->error_text() if $openldap->{mesg}->is_error();
}

sub prepare_entry {
    my ($src_entry, $type) = @_;

    # Read the filter field of Active Directory. 
    my $f_f_ad = $config_sync->{general}->{filter};

    given ($type) {
        when ('user') {

            # Read the filter map of OpenLDAP.
            my $f_f_ol = $config_sync->{person_map}->{$f_f_ad};
            my $value  = $src_entry->get_value($f_f_ad);
            my $filter = "($f_f_ol=$value)";
            my $result = $openldap->search(
                {   base   => $openldap->{config}->{base},
                    scope  => "sub",
                    filter => $filter
                }
            );

            my $dest_entry
                = $result->count > 0
                ? $result->shift_entry
                : Net::LDAP::Entry->new;

            # prepare dn if no have
            unless ($dest_entry->dn){
                my $field = $config_sync->{general}->{rdn_user_field_dst};
                my $dn = $field . '=' . $value . ',' . $openldap->base_people;
                $dest_entry->dn($dn);
            }

            # prepare attrs if attr list is empty
            unless ( $dest_entry->attributes ) {
                $dest_entry->add(
                    objectClass => [
                        'person',        'organizationalPerson',
                        'inetOrgPerson', 
                    ],
                );

                foreach ( keys %{ $config_sync->{person_map} } ) {
                    my $value_src = $src_entry->get_value( $_, asref => 1 );
                    if ($value_src ne '') {
                        $dest_entry->add(
                            $config_sync->{person_map}->{$_} =>
                                $src_entry->get_value($_),
                        );
                    } else {
                        say "bad attr: $_";
                    }
                }
                say "new entry";
            }
            else {    #update
                say "updating ...";
                foreach ( keys %{ $config_sync->{person_map} } ) {
                    my $value_src = $src_entry->get_value( $_, asref => 1 );
                    my $value_dst = $dest_entry->get_value(
                        $config_sync->{person_map}->{$_},
                        asref => 1 
                    );

                    if ($value_src){
                        if ( $value_dst ){
                            $dest_entry->replace( 
                             $config_sync->{person_map}->{$_} => 
                                $src_entry->get_value($_),
                            ); 
                        } 
                        else {
                            $dest_entry->add(
                                $config_sync->{person_map}->{$_} =>
                                    $src_entry->get_value($_),
                            );
                        }
                    } else {
                        say "bad attr: $_";
                    }

                }
            }

            return $dest_entry;
        }
    }
}

=head2 sync

Recibe un objeto Net::LDAP::Search, y sincroniza las entradas con OpenLDAP.
Si la entrada ya existe en OpenLDAP, reemplaza sus atributos. 
Si la entrada no existe en OpenLDAP, la crea.

=cut

sub sync {
    my ($entry) = @_;
    my $result = $entry->update($openldap);
    return $result->is_error ? 0 : 1;
}


sub get_high_usn {
    my $ldap = shift;
    my $dse = $ldap->root_dse(attrs => ['highestCommittedUSN']);
    my $usn = $dse->get_value('highestCommittedUSN') || die $@;
    return $usn;
}

sub store_high_usn {
    my $usn = shift;
    $db->put("highestCommittedUSN",$usn);
}

sub fetch_high_usn {
    return $db->get("highestCommittedUSN");
}

sub base_people {
    my $config = $ad->{config};
    my $base = $config->{people_rdn} . $config->{base};
    return $base;
}

sub black_list {
    my $entry = shift;
    my @black_list = qw/CN=Computers DnsUpdateProxy SUPPORT Administrator root/;

    for (@black_list){
        if ($entry->dn =~ m/$_/){
            return 1;
        }
    }

    return 0;
}

sub get_rdn {
    my $dn = shift;

    return substr $dn,0,index($dn,',');

}
