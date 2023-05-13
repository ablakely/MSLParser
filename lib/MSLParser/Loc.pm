package MSLParser::Loc;

sub new {
    my ($class, $fp, $row, $col) = @_;

    my $self = {
        file_path   => $fp,
        row         => $row + 1,
        col         => $col + 1
    };

    return bless($self, $class);
}

sub display {
    my $self = shift;

    return sprintf("%s:%d:%d",
        $self->{file_path},
        $self->{row},
        $self->{col}
    );
}


1;