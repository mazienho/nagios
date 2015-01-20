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
use Nagios::Plugin;

BEGIN {
    no warnings 'redefine';
    *Nagios::Plugin::Functions::get_shortname = sub {
        return undef;    # suppress output of shortname
    };
}

my $version = "0.0.1";

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
    default  => "localhost"
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
np->add_arg(
	spec	 => 'port|P=i',
	help 	 => $messages->{'help_port'},
	required => 0,
	default	 => 22,
);




#==============================================================#
#                              MAIN                            #
#==============================================================#

$np->getopts();


#==============================================================#
#                          Subroutines                         #
#==============================================================#
