package MSLParser::Token;

use strict;
use warnings;
use Carp;


sub new {
    my ($class, $loc, $type, $value) = @_;
    my $self = {
        type    => $type,
        value   => $value,
        loc     => $loc
    };

    return bless($self, $class);
}

sub parse_args {
    my ($self) = @_;

    return 0 if ($self->{type} ne "TOKEN_BARGLIST");

    my @tmp = split(/\:/, $self->{value});
    return {
        network => shift @tmp,
        type    => shift @tmp,
        text    => shift @tmp,
        channel => shift @tmp
    };
}

1;