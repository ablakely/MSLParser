#!/usr/bin/perl -w

use lib './lib';
use strict;
use warnings;
use MSLParser;

my $parser = MSLParser->new();

$parser->parse("./test.msl");