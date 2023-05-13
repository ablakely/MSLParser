package MSLParser;

use strict;
use warnings;
use Carp;
use MSLParser::Lexer;

sub new {
    my $class = shift;
    my $self = {};

    return bless($self, $class);
}

sub parse {
    my ($self, $file) = @_;
    my $source;

    open(my $fh, "<", $file) or croak("Error: cannot open file $file: $!");
    {
        local $/;
        $source = <$fh>;
    }
    close($fh) or croak("Error: cannot close file $file: $!");
    return undef if (!$source);

    my $lexer = MSLParser::Lexer->new($source, $file);

    while (my $token = $lexer->next_token()) {
        printf("%s:%s: %s\n", $token->{loc}->display(), $token->{type}, $token->{value});
    }

    #my $fn = $lexer->parse_function();
    #print "Got token [Type: $fn->{type}]: $fn->{value}\n" if ($fn);
}

1;