package MSLParser::Lexer;

use strict;
use warnings;
use Carp;

use MSLParser::Token;
use MSLParser::Loc;

use constant {
    TOKEN_NAME      => "TOKEN_NAME",
    TOKEN_OPAREN    => "TOKEN_OPAREN",
    TOKEN_CPAREN    => "TOKEN_CPAREN",
    TOKEN_OCURLY    => "TOKEN_OCURLY",
    TOKEN_CCURLY    => "TOKEN_CCURLY",
    TOKEN_NUMBER    => "TOKEN_NUMBER",
    TOKEN_STRING    => "TOKEN_STRING",
    TOKEN_RETURN    => "TOKEN_RETURN",
    TOKEN_BARGLIST   => "TOKEN_BARGLIST"
};

sub new {
    my ($class, $source, $file) = @_;

    my @src = split(//, $source);

    my $self = {
        file_path   => $file,
        source      => \@src,
        cur         => 0,
        bol         => 0,
        row         => 0,
        _argmode    => 0,
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
    my $type_name = shift;
    my $token = $self->next_token();

    if (!$token) {
        printf("%s: ERROR: expected %s but got end of file.\n",
            $self->loc()->display(),
            $type_name
        );

        return 0;
    }

    foreach my $type (@_) {
        if ($token->{type} eq $type) {
            return $token;
        }
    }

    if ($token->{type} ne $type_name) {
        printf("%s: ERROR: expected %s but got %s\n",
            $self->loc()->display(),
            join(" or ", @_),
            $token->{type}
        );

        return 0;
    }

    return $token;
}

sub parse_block {
    my ($self) = @_;

    return 0 if (!$self->expect_token(TOKEN_OCURLY));

    my @block;

    while (1) {
        my $cmd = $self->expect_token(TOKEN_NAME);
        return 0 if (!$cmd);
        last if ($cmd->{type} eq TOKEN_CCURLY);

    }

    my $args = $self->expect_token(TOKEN_BARGLIST);

    return $args;
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

        return MSLParser::Token->new($loc, TOKEN_NAME, $value);
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
}

1;