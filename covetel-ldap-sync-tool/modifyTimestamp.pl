#!/usr/bin/perl
use common::sense;
use DBM::Deep;

my $db = DBM::Deep->new(
    file => "sync.db",
    locking => 1,
    autoflush => 0,
    pack_size => 'small',
);

printf "%s\n",$db->get("modifyTimestamp");
