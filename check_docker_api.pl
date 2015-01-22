#!/usr/bin/perl
#
#=============================================================#
#                 mazienho <mazienho@gmx.de>                  #
#=============================================================#

#######################################
#
# Version 0.0.1
#
#          History / Changelog
#
# 2015-01-20
# Beginn of check creation
#
#######################################
#
# TODO
#
# - API or SSH?
#
# Help / error messages
#
#######################################

use strict;
use warnings;
#use Net::SSH::Perl;
use Nagios::Plugin;

BEGIN {
    no warnings 'redefine';
    *Nagios::Plugin::Functions::get_shortname = sub {
        return undef;    # suppress output of shortname
    };
}

my $version = "0.0.1";

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
    shortname => 'Docker-container',
    usage     => $messages->{'help_usage'},
    blurb     => 'Developed by Matthias Bouws',
    version   => $version,
);
#==============================================================#
#                     Command line options                     #
#==============================================================#

# Docker hostname
$np->add_arg(
    spec     => 'host|H=s',
    help     => $messages->{'help_host'},
    default  => 'localhost',
    required => 1,
    );

# Check mode
$np->add_arg(
    spec     => 'mode|m=s',
    help     => $messages->{'help_mode'},
    default  => "con-count",
    required => 1,
    );

# Warning threshold
$np->add_arg(
    spec     => 'warning|w=i',
    help     => $messages->{'help_warning'},
    required => 0,
    );

# Critical threshold
$np->add_arg(
	spec	 => 'critical|c=i',
	help 	 => $messages->{'help_critical'},
	required => 0,
    );

# User to login
$np->add_arg(
	spec	 => 'user|u=s',
	help 	 => $messages->{'help_user'},
	required => 0,
    );

# Password for user
$np->add_arg(
	spec	 => 'password|p=s',
	help 	 => $messages->{'help_password'},
	required => 0,
    );

# SSH port
$np->add_arg(
	spec	 => 'port|P=i',
	help 	 => $messages->{'help_port'},
	required => 0,
	default	 => 22,
    );

# SSH Keyfile
$np->add_arg(
    spec     => 'keyfile|k=s',
    help     => $messages->{'help_keyfile'},
    required => 0,
    #default  => "~/.ssh/id_rsa",
    );

#==============================================================#
#                              MAIN                            #
#==============================================================#

$np->getopts();

my $host = $np->opts->host;
my $user = $np->opts->user;
my $passw = $np->opts->password;
my $port = $np->opts->port;
my $keyfile = $np->opts->keyfile;

#my $result = `curl -s -XGET http://$host:$port/containers/json | jq '. | length'`;
my $result = `curl -s http://$host:$port/containers/json | jq '. | length'`;
#çhomp $result;


print "$result containers are currently running.\n";
#print "Options \nUser: $user\nPassword: $passw";

#print "Now SSH...\n";

#my @output = `ssh $user\@$host -p $port -i $keyfile -v "ls -ltr ~/"`;
#my @output = `curl -s -XGET http://eos-fuji:2375/containers/json`;
#print "OUTPUT: \n@output";

# my @output = `ssh $user\@localhost -p $port "which perl"`;

# print "output: @output";


 
# my $host = "bananapi";
# my $user = "mbouws";
# my $password = "password";
 
# #-- set up a new connection
# # my $ssh = Net::SSH::Perl->new($host);
# # #-- authenticate
# # $ssh->login($user, $pass);
# #-- execute the command
# #my($stdout, $stderr, $exit) = $ssh->cmd("ls -l /home/$user");
# #my user = mbouws
# #my file = /home/mbouws

# my @KEYFILE = ("~/.ssh/id_rsa");
# my $ssh = Net::SSH::Perl->new($host, debug=>1, identity_files=>\@KEYFILE);
# #my($stdout, $stderr, $exit) = $ssh->cmd("ls -l /home/$user");
# my @output = $ssh->cmd("ls -l /home/$user");
# print "Output: @output";

#==============================================================#
#                          Subroutines                         #
#==============================================================#
