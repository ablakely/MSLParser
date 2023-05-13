package MSLParser::Alias;

use strict;
use warnings;
use Carp;

sub new {
    my ($class, $name, $body) = @_;

    my $self = {
        name => $name,
        body => $body
    };

    return bless($self, $class);
}


1;