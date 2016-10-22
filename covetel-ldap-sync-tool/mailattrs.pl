#!/usr/bin/env perl
use common::sense;
use lib qw{/root/covetel-ldap/lib};
use Covetel::LDAP::OpenLDAP;
use Log::Dispatch::File;


my $ldap = Covetel::LDAP::OpenLDAP->new({config => '/opt/ldap-sync/openldap.ini'});

my $attrs_to_add;

$attrs_to_add->{mailHost} = '192.168.22.4';
$attrs_to_add->{mailQuotaSize} = '2048'; # Expresado en Megas


my $log = Log::Dispatch->new;

$log->add(
Log::Dispatch::File->new(
	name        => 'mailattrs.log',
	min_level   => 'debug',
	filename    => '/opt/covetel-ldap-sync-tool/mailattrs.log',
	mode        => '>>',
),
);

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

				my @origin_objectclass = @objectclass;
    
                push @objectclass, "top" unless grep {/top/} @objectclass; 
                push @objectclass, "qmailUser" unless grep {/qmailUser/} @objectclass; 
                
                my @attrs = $entry->attributes( nooptions => 1);

                foreach my $attr (keys %{$attrs_to_add}){
                   $entry->add( $attr => $attrs_to_add->{$attr} ) unless grep {/$attr/} @attrs;
                }

				if ( scalar @objectclass > scalar @origin_objectclass ){

						$entry->replace(
							objectClass => [ @objectclass ],
						);

						my $resp = $entry->update($ldap->{server});

						if ($resp->is_error){
							&logger({
								level => 'error',
								message => 'Error in: '  . $entry->dn,
							});
							&logger_error($resp);
						} else {
                    		&logger({
                                level => 'info',
                                message => "Actualizando la entrada " . $entry->dn,
                            });
						}
				} else {
					# nothing to do
					#&logger({
					#	level => 'info',
					#	message => "No hay nada que hacer con: " . $entry->dn,
					#});
					
				}
            }
        }
}


sub logger {
    my $options = shift;

    my $timestamp = localtime;

    $log->log(
        level   => $options->{'level'},
        message => localtime . ' - ' .$options->{'message'} . "\n",
    );
}

sub logger_error {
	my ($resp) = @_;

	&logger({
		level => 'error',
		message => $resp->error, 
	});
	&logger({
		level => 'error',
		message => $resp->error_name, 
	});
	&logger({
		level => 'error',
		message => $resp->error_text, 
	});
	&logger({
		level => 'error',
		message => $resp->error_desc, 
	});
}
