package MSLParser::Implementations;

use strict;
use warnings;
use Carp;

use Data::Dumper;

sub interpolate {
    my ($self, $str) = @_;

    if ($str =~ /\$(.*?)\((.*?)\)/) {
        if (exists($self->{aliases}->{$1})) {
            my @args = split(/,[\s]?/, $2);

            my $tmp = &{$self->{aliases}->{$1}}($self, @args);
            $str =~ s/\$\Q$1\E\(\Q$2\E\)/$tmp/;
        }
    } elsif ($str =~ /\$(.*)/) {
        if ($1 =~ /^\+/) {
            my @tmp = split(/[\s]\$\+[\s]/, $str);
            my $res = join("", @tmp);
            
            $str = interpolate($self, $res);
        } elsif (exists($self->{aliases}->{$1})) {
            my $tmp = &{$self->{aliases}->{$1}}();
            $str =~ s/\$\Q$1\E/$tmp/;
        }
    } elsif ($str =~ /\%(.*)/) {
        if (exists($self->{vars}->{"\%$1"})) {
            my $tmp = $self->{vars}->{"\%$1"};
            $str =~ s/\%\Q$1\E/$tmp/;
        }
    }

    return $str;
}

sub load {
    my ($env) = @_;

    # /set
    $env->{aliases}->{set} = sub {
        my $self = shift;
        my ($var, $val) = split(/ /, $_[0], 2);

        $self->{vars}->{$var} = interpolate($self, $val);
    };

    # /echo
    $env->{aliases}->{echo} = sub {
        my ($self, $msg) = @_;

        $msg = interpolate($self, $msg);

        print "$msg\n";
    };

    # $true
    $env->{aliases}->{true} = sub {
        return 1;
    };

    # $false
    $env->{aliases}->{false} = sub {
        return 0;
    };

    # /dumpstate - prints the interpeters current state
    $env->{aliases}->{dumpstate} = sub {
        my ($self) = @_;

        print Dumper($self);
    };

    # $+ - Combines 2 or more strings
    # Hello $+ World = HelloWorld
    # $+(Hello, World) = HelloWorld
    $env->{aliases}->{'+'} = sub {
        my $self = shift;
        my @tmp;

        foreach my $t (@_) {
            push(@tmp, interpolate($t));
        }

        return join("", @tmp);
    };

}


our @EXPORT_OK = qw(interpolate);
1;