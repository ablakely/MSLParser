package MSLParser::Block;

use strict;
use warnings;
use Carp;

sub new {
    my ($class, $type, $condition, $body) = @_;
    my $self = {
        type => $type,
        condition => $condition,
        body => $body
    }

    return bless($self, $class);
}

1;