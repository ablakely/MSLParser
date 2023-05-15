package MSLParser::Condition;

use strict;
use warnings;
use Carp;

use MSLParser::Implementations;

sub new {
    my ($class, $loc, $type, $condition, $true_block, $false_block, $elseif_blocks) = @_;

    my $self = {
        loc       => $loc,
        value      => "$condition",
        type      => $type,                 # CONDITION_IF, CONDITION_ELSE, CONDITION_ELSEIF or CONDITION_WHILE
        condition => $condition,
        true      => $true_block,           # MSLParser::Block->new()
        false     => $false_block,          # MSLParser::Block->new()
        elseif    => $elseif_blocks         # (MSLParser::Condition->new())
    };

    return bless($self, $class);
}

sub evaluate {
    my ($self, $env) = @_;

    my $condition = interpolate($self->{condition});

    # process condition to 1 or 0


}

sub display {
    my ($self) = @_;

    return sprintf("%s:%s:%s: %s",
        $self->{loc}->{file_path},
        $self->{loc}->{row},
        $self->{loc}->{col},
        $self->{value}
    );
}

1;