package MSLParser::Block;

use strict;
use warnings;
use Carp;

sub new {
    my ($class, $loc, $type, $body) = @_;
    my $self = {
        loc  => $loc,
        type => $type,              # IF_BLOCK, ELSE_BLOCK, ELSEIF_BLOCK, or WHILE_BLOCK
        body => $body               # arrayref of MSLParser::AliasCall->new()
    };

    return bless($self, $class);
}

sub exec {
    my ($self, $env) = @_;

    for (my $i = 0; $i < scalar(@{$self->{body}}); $i++) {
        $self->{body}[$i]->exec($env);
    }
}

1;