package MSLParser;

use strict;
use warnings;
use Carp;

use MSLParser::Lexer;
use MSLParser::Implementations;

use Data::Dumper;

sub new {
    my $class = shift;
    my $self = {
        ENV => {
            aliases => {},
            vars    => {},
            hashes  => {},
            events  => {} 
        }
    };

    MSLParser::Implementations::load($self->{ENV});

    return bless($self, $class);
}

sub setvar {
    my ($self, $var, $val) = @_;

    $self->{ENV}->{vars}->{$var} = $val;
}

sub sethash {
    my ($self, $var, $val) = @_;

    $self->{ENV}->{vars}->{$var} = $val;
}

sub alias {
    my ($self, $name, $subref) = @_;

    print "adding alias $name\n";

    $self->{ENV}->{aliases}->{$name} = $subref;
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

    my $lexer = MSLParser::Lexer->new($source, $file, $self->{ENV});

    while (my $token = $lexer->next_token()) {
        printf("%s:%s: %s\n", $token->{loc}->display(), $token->{type}, $token->{value});

        if ($token->{type} eq "ALIAS_CALL") {
            $token->exec($self->{ENV});
        }

        if ($token->{type} eq "TOKEN_BARGLIST") {
            my $args = $token->parse_args();

            printf("Network = %s\ntype = %s\ntext = %s\nchan = %s\n",
                $args->{network},
                $args->{type},
                $args->{text},
                $args->{channel}
            ) if ($args->{type} eq "TEXT");
        }

        if ($token->{type} eq "IF_BLOCK") {
            push(@{$self->{ENV}->{conditions}}, $token);
        }
    }

    #my $fn = $lexer->parse_function();
    #print "Got token [Type: $fn->{type}]: $fn->{value}\n" if ($fn);
}

1;