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


1;