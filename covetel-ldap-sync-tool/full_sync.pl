#!/usr/bin/perl
use common::sense;
use DBM::Deep;

my $db = DBM::Deep->new(
    file => "sync.db",
    locking => 1,
    autoflush => 0,
    pack_size => 'small',
);

$db->put("highestCommittedUSN",0);
$db->put("modifyTimestamp",0);
