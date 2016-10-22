#!/usr/bin/env perl
use common::sense;
use Config::Any::INI;
use Data::Dumper;

my $config = Config::Any::INI->load("sync.ini");

for ( keys %{$config->{person_map}} ){
    say "$_ => " . $config->{person_map}->{$_};
}

print Dumper $config;

1;
