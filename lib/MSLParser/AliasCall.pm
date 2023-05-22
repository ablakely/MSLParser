package MSLParser::AliasCall;

use strict;
use warnings;
use Carp;

sub new {
    my ($class, $loc, $name, $args) = @_;

    my $self = {
        type        => "ALIAS_CALL",
        name        => $name,
        args        => $args,
        loc         => $loc,
        value       => "$name $args"
    };

    return bless($self, $class);
}

sub display {
    my ($self) = @_;

    return sprintf("%s:%s:%s",
        $self->{loc}->{file_path},
        $self->{loc}->{row},
        $self->{loc}->{col}
    );
}

sub exec {
    my ($self, $env) = @_;

    &{$env->{aliases}->{$self->{name}}}($env, $self->{args});
}


1;
