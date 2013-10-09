use IO::Socket;

# Just subs that are used in tests
# Code is taken from RPC::XML

sub find_port {
    my $start_at = $_[0] || 9000;

    my ($port, $sock);

    for ($port = $start_at; $port < ($start_at + 1000); $port++) {
        $sock = IO::Socket->new(Domain   => AF_INET,
                                PeerAddr => 'localhost',
                                PeerPort => $port);
        return $port unless ref $sock;
    }

    '';
}

sub start_server {
    my $S = shift;

    my $pid;

    if (! defined($pid = fork())) {
        die "fork() error: $!, stopped";
    } elsif ($pid) {
        return $pid;
    } else {
        $S->server_loop(@_);
        exit; # When the parent stops this server, we want to stop this child
    }
}

sub stop_server {
    my $pid = shift;

    # Per RT 27778, use 'KILL' instead of 'INT' as the stop-server signal for
    # MSWin platforms:
    my $SIGNAL = ($^O eq "MSWin32") ? 'KILL' : 'INT';
    kill $SIGNAL, $pid;
    sleep 2; # give the old sockets time to go away
}

1;
