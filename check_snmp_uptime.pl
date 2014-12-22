#!/usr/bin/perl

###############################################################
#                                                             #
#                 mazienho <mazienho@gmx.de>                  #
#                                                             #
###############################################################

##########################################################################################
#
# Version 1.2.0
#
#          History / Changelog
#
# 2013-11-15
# *1.2.0
# Added SNMPv3 support
#
# 2013-04-22
# *1.1.1
# Bugfixing in perfdata output
# Added option "week" for time unit in performance data output
#
# 04/2013
# *1.1.0
# Added option for performance data unit for more readability in perfdata output
#
# 03/2013
# *1.0.1
# Added option for different sysuptime OID
#
# 02/2013
# *1.0.0
# First working version
#
##########################################################################################
#
#
# TODO
#
# Help / error messages
#
##########################################################################################

use strict;
use warnings;
use Nagios::Plugin;
use Net::SNMP;

## PROCESSING OF COMMAND LINE ARGUMENTS

BEGIN {
    no warnings 'redefine';
    *Nagios::Plugin::Functions::get_shortname = sub {
        return undef;    # suppress output of shortname
    };
}

my $version = "1.2.0";

#Default OID of system uptime
#Can be modified by using the Option '-o'
my $uptime_oid = '1.3.6.1.2.1.1.3.0';

# Help and error messages
my $messages = ();
$messages->{'help_usage'}
    = "Usage: \n ./check_snmp_uptime.pl -H <HOST> [-C <COMMUNITY>] [-o <OID>] [-w <WARNING>] [-c <CRITICAL>]";
$messages->{'help_host'} = "IP or DNS name of the remote host";
$messages->{'help_community'}
    = "SNMP v1/v2c Communitystring (Default: public).";
$messages->{'help_warning'}
    = "Warning threshold or range (e.g. 20d:30d). Valid time units are w (week), d (day), h (hours), m (minutes), s (seconds)\n   Time addition is accepted: 20d+8h:10h+2m\nSee Nagios development guidelines for Syntax: http://nagiosplug.sourceforge.net/developer-guidelines.html#THRESHOLDFORMAT";
$messages->{'help_critical'}
    = "Critical threshold or range (e.g. 20d:30d). Valid time units are w (week), d (day), h (hours), m (minutes), s (seconds)\n   Time addition is accepted: 20d+8h:10h+2m\nSee Nagios development guidelines for Syntax: http://nagiosplug.sourceforge.net/developer-guidelines.html#THRESHOLDFORMAT";
$messages->{'help_protocol'} = "SNMP Version. <1|2c|3>";
$messages->{'help_port'}     = "Remote Port. Default: 161";
$messages->{'help_oid'}
    = "The numerical OID for sysuptime (e.g. \"1.3.6.1.2.1.1.3.0\"). This example is also the default value";
$messages->{'help_timeout'} = "Timeout in seconds. Default: 30s";
$messages->{'help_unit'}
    = "Time unit of returned value for performance data. <d|h|s>\; Default s";

#Error Messages
$messages->{'error_threshold_syntax'} = "Wrong threshold syntax.";

my $np = Nagios::Plugin->new(
    shortname => 'Uptime',
    usage     => $messages->{'help_usage'},
    blurb     => 'Developed by Matthias Bouws',
    version   => $version,
);

##################################################################
#                     Command line options                       #
##################################################################

#Hostname
$np->add_arg(
    spec     => 'host|H=s',
    help     => $messages->{'help_host'},
    required => 1,
);

#Community String
$np->add_arg(
    spec     => 'community|C=s',
    help     => $messages->{'help_community'},
    default  => "public",
    required => 0,
);

#Warning Threshold
$np->add_arg(
    spec     => 'warning|w=s',
    help     => $messages->{'help_warning'},
    default  => '120s:',
    required => 0,
);

#Critical Threshold
$np->add_arg(
    spec     => 'critical|c=s',
    help     => $messages->{'help_critical'},
    default  => '60s:',
    required => 0,
);

#Protocol <1|2c|3>
$np->add_arg(
    spec     => 'protocol|P=s',
    help     => $messages->{'help_protocol'},
    default  => '2c',
    required => 0,
);

#Port
$np->add_arg(
    spec     => 'port|p=i',
    help     => $messages->{'help_port'},
    default  => 161,
    required => 0,
);

#OID
$np->add_arg(
    spec     => 'oid|o=s',
    help     => $messages->{'help_oid'},
    default  => $uptime_oid,
    required => 0,
);

#Time unit
$np->add_arg(
    spec     => 'unit|T=s',
    help     => $messages->{'help_unit'},
    default  => 's',
    required => 0,
);

#SNMP v3 arguments
#Username
$np->add_arg(
    spec     => 'username|U=s',
    help     => $messages->{'help_username'},
    default  => undef,
    required => 0,
);

#Authprotocol
$np->add_arg(
    spec     => 'authprotocol|a=s',
    help     => $messages->{'help_authprotocol'},
    default  => undef,
    required => 0,
);

#Authpassword
$np->add_arg(
    spec     => 'authpassword|A=s',
    help     => $messages->{'help_authpassword'},
    default  => undef,
    required => 0,
);

#Privprotocol
$np->add_arg(
    spec     => 'privprotocol|x=s',
    help     => $messages->{'help_privprotocol'},
    default  => undef,
    required => 0,
);

#Privpassword
$np->add_arg(
    spec     => 'privpassword|X=s',
    help     => $messages->{'help_privpassword'},
    default  => undef,
    required => 0,
);

#Privkey
$np->add_arg(
    spec     => 'privkey|z=s',
    help     => $messages->{'help_privkey'},
    default  => undef,
    required => 0,
);

#Authkey
$np->add_arg(
    spec     => 'authkey|q=s',
    help     => $messages->{'help_authkey'},
    default  => undef,
    required => 0,
);

#========================================================================================#
#                                                                                        #
#                                         Main                                           #
#                                                                                        #
#========================================================================================#

$np->getopts();

#Open SMNP session
#SNMP v1 or v2c
my ( $session, $error );
if ( $np->opts->protocol eq '1' || $np->opts->protocol eq '2c' ) {
    ( $session, $error ) = Net::SNMP->session(
        Hostname  => $np->opts->host,
        Community => $np->opts->community,
        Version   => $np->opts->protocol,
        Port      => $np->opts->port,
        Timeout   => $np->opts->timeout,
    );
}

#SNMP v3 - without privpass
elsif ( !defined $np->opts->privpassword ) {
    ( $session, $error ) = Net::SNMP->session(
        Hostname     => $np->opts->host,
        Version      => $np->opts->protocol,
        Port         => $np->opts->port,
        Timeout      => $np->opts->timeout,
        Username     => $np->opts->username,
        Authprotocol => $np->opts->authprotocol,
        Authpassword => $np->opts->authpassword,
    );
}

#SNMP v3 - including privpass
else {
    ( $session, $error ) = Net::SNMP->session(
        Hostname     => $np->opts->host,
        Version      => $np->opts->protocol,
        Port         => $np->opts->port,
        Timeout      => $np->opts->timeout,
        Username     => $np->opts->username,
        Authprotocol => $np->opts->authprotocol,
        Authpassword => $np->opts->authpassword,
        Privpassword => $np->opts->privpassword,
        Privprotocol => $np->opts->privprotocol,
    );
}
die "session error: $error" unless ($session);

#Disable NET::SNMP translation of timeticks and get numerical result (in 1/100 of a sec)
$session->translate(0);
my $result = $session->get_request( $np->opts->oid );
die "request error: " . $session->error unless ( defined $result );
$session->close;

#Convert 1/100sec into seconds
my $uptime_seconds = int( $$result{ $np->opts->oid } / 100 );

#Read perf-data-time unit and set divisor
my $divisor = set_divisor( $np->opts->unit );

$np->set_thresholds(
    warning  => &parse_threshold( $np->opts->warning,  1 ),
    critical => &parse_threshold( $np->opts->critical, 1 ),
);

#Perfdata unit according to given unit
$np->add_perfdata(
    label => "Uptime_"
        . (
          $np->opts->unit eq 's' ? 'sec'
        : $np->opts->unit eq 'm' ? 'min'
        : $np->opts->unit eq 'h' ? 'hrs'
        : $np->opts->unit eq 'd' ? 'day'
        : 'week'
        ),
    value => $uptime_seconds / $divisor,
    uom =>
        undef
    ,    #$np->opts->unit, <- does not work with other units than seconds
    warning  => &parse_threshold( $np->opts->warning,  $divisor ),
    critical => &parse_threshold( $np->opts->critical, $divisor ),
);

#Convert seconds into human readable output message
$np->nagios_exit(
    return_code => $np->check_threshold($uptime_seconds),
    message     => "Uptime: " . &readable_time($uptime_seconds),
);

#========================================================================================#
#                                                                                        #
#                                Subroutines                                             #
#                                                                                        #
#========================================================================================#

#Convert seconds into human readable time:
sub readable_time {
    my $uptime_seconds = shift;
    my $day            = 0;
    my $hour           = 0;
    my $minute         = 0;
    my $second         = 0;

    $day            = int( $uptime_seconds / 86400 );
    $uptime_seconds = ( $uptime_seconds - 86400 * $day );

    $hour           = int( $uptime_seconds / 3600 );
    $uptime_seconds = ( $uptime_seconds - 3600 * $hour );

    $minute         = int( $uptime_seconds / 60 );
    $uptime_seconds = ( $uptime_seconds - 60 * $minute );

    $second = $uptime_seconds;

    my $time
        = $day . " day"
        . ( $day > 1  ? "s " : " " )
        . ( $hour > 9 ? ""   : "0" )
        . $hour . ":"
        . ( $minute > 9 ? "" : "0" )
        . $minute . ":"
        . ( $second > 9 ? "" : "0" )
        . $second;
    return $time;
}

#Parse threshold to required syntax
#Divisor = 1 for calculating uptime; otherwise according to given value for perfdata output
sub parse_threshold {

    #my $threshold = shift;
    my $threshold = $_[0];
    my $divisor   = $_[1];
    my $return    = "";

    #Check if threshold-syntax is OK
    if (   $threshold !~ /^\d+[wdhms](\+\d+[wdhms])*:?$/
        && $threshold
        !~ /^@?\d+[wdhms](\+\d+[wdhms])*:\d+[wdhms](\+\d+[wdhms])*$/ )
    {
        $np->nagios_exit(
            return_code => 3,
            message     => $messages->{'error_threshold_syntax'},
        );
    }

    if ( $threshold =~ /:/ ) {
        if ( $threshold =~ /\w:$/ ) {
            chop($threshold);
            $return = to_seconds( $threshold, $divisor ) . ':';
        }
        elsif ( $threshold =~ /^@/ ) {
            $threshold = substr( $threshold, 1 );
            $return = '@' . find_ranges( $threshold, $divisor );
        }
        else {
            $return = find_ranges( $threshold, $divisor );
        }
    }
    else {
        $return = to_seconds( $threshold, $divisor );
    }
    return $return;
}

#If threshold ranges are given -> Convert them into seconds
sub find_ranges {
    my @ranges       = split /:/, $_[0];
    my $divisor      = $_[1];
    my @second_range = ();
    foreach (@ranges) {
        my $second = 0;
        $second += to_seconds( $_, $divisor );
        push( @second_range, $second );
    }
    return ( join( ':', @second_range ) );
}

#Calculate 'human readable time' given in threshold arguments to time value in seconds
#If time addition in threshold value -> add these values
sub to_seconds {
    my $given   = $_[0];    #shift;
    my $divisor = $_[1];
    if ( $given =~ /\+/ ) {
        my $add_seconds = 0;
        my @time_addition = split /\+/, $given;
        foreach (@time_addition) {
            $add_seconds += to_seconds( $_, $divisor );
        }
        return $add_seconds;
    }
    if ( $given =~ /d/ ) {
        return ( $` * 86400 / $divisor );
    }
    elsif ( $given =~ /h/ ) {
        return ( $` * 3600 / $divisor );
    }
    elsif ( $given =~ /m/ ) {
        return ( $` * 60 / $divisor );
    }
    elsif ( $given =~ /s/ ) {
        return ( $` / $divisor );
    }
}

#Find and set divisor
sub set_divisor {
    my $divisor = shift;
    if ( $divisor eq 'w' ) {
        return 604800;
    }
    elsif ( $divisor eq 'd' ) {
        return 86400;
    }
    elsif ( $divisor eq 'h' ) {
        return 3600;
    }
    elsif ( $divisor eq 'm' ) {
        return 60;
    }
    else {
        return 1;
    }
}
