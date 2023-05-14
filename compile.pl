#!/usr/bin/perl -w

use lib './lib';
use strict;
use warnings;
use MSLParser;

my $parser = MSLParser->new();

$parser->alias('msg', sub {
    my ($self, $msg) = @_;

    print "$msg\n";
});

$parser->parse("./test.msl");