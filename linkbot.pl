#!/usr/bin/perl -w
###--- Perl IRC Network Linkbot.                               ---###
### written by jnbek@yahoo.com                                    ###
### This code is licensed under the terms of the GPL 3.0 License. ###
### See http://www.gnu.org/licenses/gpl-3.0-standalone.html       ###
use strict;
use warnings;
use Net::IRC;
use JSON;
use FindBin;
our $version = '0.4';
###---- Configuration ----###
my $server   = 'your.servername.com';  #The server/network hub.
my $port     = 6667;                   #The server's port, usually 6667
my $nick     = 'linkbot';              #The Bot's nickname (REQUIRED).
my $opernick = 'opernick';             # Nick for /oper command (REQUIRED).
my $operpass = 'operpass';             # Password for /oper $opernick (REQUIRED)
my $nspass   = 'nspass';               # Nickserv password (REQUIRED)
my $ircname     = "something creative";      # This is the bot's 'tagline'.
my $website     = "http://ircd.yournetwork.com/";  # Your IRC Network Homepage.
my $filename    = '/path/to/network_links.json';
my $testchannel = '';                              # Leave Blank for none.
my $want_weeks = 0;    # Show weeks instead of days in uptime.
my @global_hours = qw(12 18); #Fire the GLOBAL msg at 12pm and 6pm only. Leave blank to always fire.
###---- End Configuration ----###

### Don't change anything below, unless you know what you're doing. ###.
my $script = $FindBin::RealScript;
my @slinks = [];
my $i      = 0;
my $irc    = new Net::IRC;
my $conn   = $irc->newconn(
    Nick    => $nick,
    Server  => $server,
    Port    => $port,
    Ircname => "$script: $ircname",
    Username => "$nick",
);
$conn->add_global_handler( '376', \&on_connect );
$conn->add_global_handler( '211', \&on_links );
$conn->add_global_handler( '219', \&on_write );
$conn->add_global_handler( '366', \&on_stats );

#Uncomment below, if you want Verbose Output.
#$conn->add_global_handler( [ 251, 252, 253, 254, 302 ], \&on_init );

sub on_connect {
    my ( $self, $event ) = @_;
    if ($testchannel) {
        print "Joining $testchannel ...\n";
        $self->join($testchannel);
        $self->privmsg( $testchannel, "Hi there." );
    }
    $self->oper( $opernick, $operpass );
    $self->privmsg( "nickserv", "IDENTIFY $nspass" );
}

sub on_init {
    my ( $self, $event ) = @_;
    my (@args) = ( $event->args );
    shift(@args);

    print "*** @args\n";
}

sub on_stats {
    my ( $self, $event ) = @_;
    if ( $i == 0 ) {
        $self->stats('l');
        $i++;
    }
}

sub on_links {
    my ( $self, $event ) = @_;
    my (@s) = ( $event->args );
    shift(@s);
    my $h = {};

    my @link = split( /\[/, $s[0] );
    return if ( $link[0] =~ m/(SendQ|services|stats)/ );
    # This next line needs to include the ports your network hub listens
    # on. STATS l will return a line for each port, as well as the
    # server so we filter those out. Each port is | seperated.
    return if ( $link[1] =~ m/(6697|6667)/ );
    my $uptime = &get_uptime( $s[6] );

    $h->{'name'}   = $link[0];
    $h->{'uptime'} = $uptime;
    push @slinks, $h;
    if ($testchannel) {
        $self->privmsg( $testchannel,
            "Server: " . $h->{'name'} . " : Up: " . $h->{'uptime'} );
    }
}

sub on_write {
    my ( $self, $event ) = @_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my (@glob) = ( $event->args );
    shift(@glob);
    shift @slinks;
    open( my $FH, '>', $filename ) || die "Failed to open $filename: $!";
    print $FH encode_json( \@slinks );
    close($FH);
    if ((!$global_hours[0]) || ($global_hours[0] && grep(!/^$hour/, @global_hours)))
    {
        $self->privmsg( "operserv", "global Server list updated. See: $website" );
    }
    $self->disconnect;
}

sub get_uptime {
    my $the_time = shift;
    my $prefix;
    my $difference   = $the_time;
    my $seconds      = sprintf( "%02.0f", $difference % 60 );
    my $from_sec     = ( $difference - $seconds ) / 60;
    my $minutes      = sprintf( "%02.0f", $from_sec % 60 );
    my $from_min     = ( $from_sec - $minutes ) / 60;
    my $hours        = sprintf( "%02.0f", $from_min % 24 );
    my $from_hours   = ( $from_min - $hours ) / 24;
    my $days_only    = sprintf( "%02.0f", $from_hours );
    my $days_4_weeks = sprintf( "%02.0f", $from_hours % 7 );
    my $from_days    = ( $from_hours - $days_4_weeks ) / 7;
    my $weeks        = sprintf( "%02.0f", $from_days );
    if ($want_weeks) {
        $prefix = "$weeks Weeks, $days_4_weeks Days";
    }
    else {
        $prefix = "$days_only Days";
    }
    my $uptime = "$prefix $hours:$minutes:$seconds";
    return $uptime;
}
$irc->start;
