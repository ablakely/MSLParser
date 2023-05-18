package MSLParser::Lexer;

use strict;
use warnings;
use Carp;

use Data::Dumper;

use MSLParser::Block;
use MSLParser::Token;
use MSLParser::Loc;
use MSLParser::AliasCall;
use MSLParser::Condition;

use constant {
    TOKEN_NAME      => "TOKEN_NAME",
    TOKEN_OPAREN    => "TOKEN_OPAREN",
    TOKEN_CPAREN    => "TOKEN_CPAREN",
    TOKEN_OCURLY    => "TOKEN_OCURLY",
    TOKEN_CCURLY    => "TOKEN_CCURLY",
    TOKEN_NUMBER    => "TOKEN_NUMBER",
    TOKEN_STRING    => "TOKEN_STRING",
    TOKEN_RETURN    => "TOKEN_RETURN",
    TOKEN_BARGLIST  => "TOKEN_BARGLIST",
    TOKEN_CONDITION => "TOKEN_CONDITION",
    ALIAS_CALL      => "ALIAS_CALL"
};

sub new {
    my ($class, $source, $file, $env) = @_;

    my @src = split(//, $source);

    my $self = {
        strace      => 1,
        file_path   => $file,
        source      => \@src,
        cur         => 0,
        bol         => 0,
        row         => 0,
        _argmode    => 0,
        _conmode    => 0,
        _contype    => "",
        _condition  => "",
        _depth      => 0,

        ENV         => $env
    };

    return bless($self, $class);
}

sub is_not_empty {
    my $self = shift;

    return $self->{cur} < scalar(@{$self->{source}});
}

sub is_empty {
    my $self = shift;

    return !$self->is_not_empty();
}

sub chop_char {
    my ($self) = shift;

    if ($self->is_not_empty()) {
        my $x = $self->{source}[$self->{cur}];
        $self->{cur}++;

        if ($x eq "\n") {
            $self->{bol} = $self->{cur};
            $self->{row}++;
        }
    }
}

sub loc {
    my $self = shift;

    return MSLParser::Loc->new($self->{file_path}, $self->{row}, $self->{cur} - $self->{bol});
}

sub isspace {
    my $s = shift;

    return $s =~ /[[:blank:]|[:cntrl:]]/;
}

sub trim_left {
    my $self = shift;

    while ($self->is_not_empty() && $self->{source}[$self->{cur}] =~ /[[:space:]]/) {
        $self->chop_char();
    }
}

sub drop_line {
    my $self = shift;

    while ($self->is_not_empty() && $self->{source}[$self->{cur}] ne "\n") {
        $self->chop_char();
    }

    $self->chop_char() if ($self->is_not_empty());
}

sub expect_token {
    my $self = shift;
    my $token = $self->next_token();

    if (!$token) {
        my $err = sprintf("%s: ERROR: expected %s but got end of file.\n",
            $self->loc()->display(),
            join(" or ", @_)
        );

        if ($self->{strace}) {
            confess $err; 
        } else {
            print $err;
        }

        return 0;
    }

    foreach my $type (@_) {
        if ($token->{type} eq $type) {
            return $token;
        }
    }

    my $err = sprintf("%s: ERROR: expected %s but got %s\n",
        $self->loc()->display(),
        join(" or ", @_),
        $token->{type}
    );

    if ($self->{strace}) {
        confess $err; 
    } else {
        print $err;
    }

    return 0;
}

sub next_token {
    my ($self) = shift;

    $self->trim_left();
    while ($self->is_not_empty() && $self->{source}[$self->{cur}] eq ";") {
        $self->drop_line();
        $self->trim_left();
    }

    return 0 if ($self->is_empty());

    my $loc   = $self->loc();
    my $first = $self->{source}[$self->{cur}]; 

    my %literal_tokens = (
        "("         => TOKEN_OPAREN,
        ")"         => TOKEN_CPAREN,
        "{"         => TOKEN_OCURLY,
        "}"         => TOKEN_CCURLY,
    );

    if (exists($literal_tokens{$first})) {
        $self->chop_char();

        if ($self->{_argmode} && $literal_tokens{$first} eq TOKEN_OCURLY) {
            $self->{_argmode} = 0;
        }
        
        if ($self->{_conmode} && $literal_tokens{$first} eq TOKEN_CPAREN) {
            $self->{_conmode} = 0;

            #return MSLParser::Block->new($self->{_contype}, parse_block());
        }

        return MSLParser::Token->new($loc, $literal_tokens{$first}, $first);
    } elsif ($first =~ /[[:alpha:]]/) {
        my $index = $self->{cur};

        while ($self->is_not_empty() && $self->{source}[$self->{cur}] =~ /[[:alnum:]]/) {
            $self->chop_char();
        }

        my $tmp = join("", @{$self->{source}});

        my $value = substr($tmp, $index, $self->{cur} - $index);

        if ($value eq "on") {
            $self->{_argmode} = 1;
        }

        if ($value eq "if" || $value eq "while") {
            $self->{_contype} = $value eq "if" ? "IF_BLOCK" : "WHILE_BLOCK";
            $self->{_conmode} = 1;

            $self->{_depth}++;
        }

        my @tmpline;
        my $tmpcur = $self->{cur};

        while ($self->{source}[$tmpcur] !~ /\}/) {
            last if ($self->{source}[$tmpcur] =~ /\n/ && $value ne "if");
            #next if ($self->{source}[$tmpcur] =~ /\s/);

            push(@tmpline, $self->{source}[$tmpcur]);
            $tmpcur++;

            if (exists($self->{ENV}->{aliases}->{$value})) {
                $self->chop_char();
            }
            
        }

        my $test = join("", @tmpline);

        if (exists($self->{ENV}->{aliases}->{$value})) {
            $test =~ s/^\s//;

            $test .= "}" if ($value eq "if");

            return MSLParser::AliasCall->new($loc, $value, $test);
        }

        return MSLParser::Token->new($loc, TOKEN_NAME, "$value");
    }

    if ($self->{_argmode}) {
        $self->chop_char();
        my $start = $self->{cur};

        while ($self->is_not_empty() && $self->{source}[$self->{cur}+1] ne '{') {
            $self->chop_char();
        }

        if ($self->is_not_empty()) {
            my $tmp   = join("", @{$self->{source}});
            my $value = substr($tmp, $start - 1, $self->{cur} - $start);

            $self->chop_char();
            return MSLParser::Token->new($loc, TOKEN_BARGLIST, "$value:");
        }
    }

    if ($self->{_conmode}) {
        $self->chop_char();
        my $start = $self->{cur};

        while ($self->is_not_empty() && $self->{source}[$self->{cur}+1] ne ')') {
            $self->chop_char();
        }

        if ($self->is_not_empty()) {
            my $tmp     = join("", @{$self->{source}});
            my $value   = substr($tmp, $start - 1, $self->{cur} - $start +2);

            $self->chop_char();

            $value =~ s/^\s+//;

            $self->{_depth}--;
            my ($trueblock, $falseblock, @elseifblocks);

            $self->chop_char();

            print "b4 blockparse: ".$self->{source}[$self->{cur}+1]."\n";

            BLOCKPARSE: {
                while (1) {
                    last BLOCKPARSE if (!$self->{source}[$self->{cur}] || $self->{source}[$self->{cur}] eq "\n");

                    print "blockparse loop++\n";
                    my @blocks = $self->parse_block();
                    last BLOCKPARSE if (@blocks);
                    last BLOCKPARSE if (!$self->{source}[$self->{cur}] || $self->{source}[$self->{cur}] eq "\n");

                    
                    print "cur: |".$self->{source}[$self->{cur}]."|\n";

                    
                    if (!join("\n", @blocks)) {
                        last BLOCKPARSE;
                    }
                    print "ddd: \n".join("\n", @blocks)."\n";

                    foreach my $block (@blocks) {
                        last BLOCKPARSE if (!$block->{body});
                        printf("dbug: %s\n", $block->{body});

                        if ($block->{type} eq "IF_BLOCK") {
                            print "true block\n";

                            $trueblock = $block;
                        } elsif ($block->{type} eq "ELSE_BLOCK") {
                            print "else block\n";

                            $falseblock = $block;
                            last BLOCKPARSE;
                        } else {
                            last BLOCKPARSE;
                        }
                    }

                }
            }

            #my $trueblock = $self->parse_block();
            return 0 if (!$trueblock);
            
            print "---here---\n";
            $self->{_conmode} = 0;

            return MSLParser::Condition->new($loc, $self->{_contype}, $value, $trueblock, $falseblock);

            #return MSLParser::Token->new($loc, TOKEN_CONDITION, "$value");
            #return MSLParser::Condition->new($loc, $value);
        }
    }
}


sub parse_block {
    my ($self) = @_;
    return 0 if (!$self->expect_token(TOKEN_OCURLY, TOKEN_CCURLY));

    my @block;

    while (1) {
        print "pb cur: |".$self->{source}[$self->{cur}]."|\n";
        return 0 if (!$self->{source}[$self->{cur}]);

        my $cmd = $self->expect_token(ALIAS_CALL, TOKEN_NAME, TOKEN_CCURLY, "IF_BLOCK");
        return 0 if (!$cmd);
        last if ($cmd->{type} eq TOKEN_CCURLY);

        print Dumper($cmd);

        if ($cmd->{type} eq "IF_BLOCK") {
            push(@block, $cmd);

            $self->{_depth}--;
        }

        if ($cmd->{value} eq "if") {
            $self->{_depth}++;
            $self->{_conmode} = 1;
            $self->{_contype} = "IF_BLOCK";


            return 0 unless ($self->expect_token(TOKEN_OPAREN));
        } else {
            push(@block, $cmd);
        }
    }

    if (my $token = $self->expect_token(TOKEN_CCURLY, TOKEN_NAME)) {
        #print "dd: ".$token->{type}."\n".
        
        return 0 if (!join("\n", @block));
        return 0 if (!$token);
        return 0 if ($token->{type} eq TOKEN_CCURLY);

        if ($token->{type} eq TOKEN_NAME && $token->{value} eq "else") {
            my @eblock = ();
            return 0 if (!$self->expect_token(TOKEN_OCURLY));
            $self->{_depth}++;

            print "here\n";

            while (1) {
                printf("----- cur: [%s] -----\n", $self->{source}[$self->{cur}]);
                my $cmd = $self->expect_token(ALIAS_CALL, TOKEN_NAME, TOKEN_CCURLY, "IF_BLOCK");
                return 0 if (!$cmd);
                last if ($cmd->{type} eq TOKEN_CCURLY);

                print "d: ".$cmd->{value}."\n";

                
                
                push(@eblock, $cmd);

                print "block=\n".join("\n", @block)."\n";
                print "eblock=\n".join("\n", @eblock)."\n";
            }

            print "---parseblock about to return---\n";
            return (MSLParser::Block->new($self->loc(), "IF_BLOCK", @block), MSLParser::Block->new($self->loc(), "ELSE_BLOCK", @eblock));
        }
    }

    return 0;
}


1;