# MSL Parser

Interpreter for [mIRC scripting language](https://en.wikipedia.org/wiki/MIRC_scripting_language) written in Perl.
This project is in the alpha stages and is not suitable for real usage yet.  A lot of the syntax does not parse yet.


# Usage

```perl
# this is mainly pseudo code as of current.

use MSLParser;
my $msl = MSLParser->new();

$msl->alias('echo', sub {
    my ($args) = @_;
    print "$args\r\n";
});

$msl->setvar('%var', 'test');
$msl->sethash('%hash', {
    testval => 1
});

$msl->load('./test.msl');

# calls a msl handler
# on *:TEXT:!test:#lobby { ... }

$msl->on_event({
    network     => "*",
    type        => "TEXT",
    text        => "!test",
    channel     => "#lobby",
    
    # mirc contexts ($nick, $host, etc)
    nick        => "Nick",
    host        => '~ab@test.example.tld'
});

$msl->tick(); # call this in main loop
```

