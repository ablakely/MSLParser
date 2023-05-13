# MSL Parser

Interpreter for [mIRC scripting language](https://en.wikipedia.org/wiki/MIRC_scripting_language) written in Perl.
This project is in the alpha stages and is not suitable for real usage yet.  A lot of the syntax does not parse yet.


# Usage

    use MSLParser;

    my $parser = MSLParser->new();

    $parser->cmd('echo', sub {
        my ($args) = @_;

        print "$args\r\n";
    });

    $parser->parse('./test.msl');


