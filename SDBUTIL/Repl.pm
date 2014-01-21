#!/usr/bin/perl
#

package SDBUTIL::Repl;

use Term::ReadLine;
use SimpleDB::Client;
use SDBUTIL::CMD::Domains;
use SDBUTIL::CMD::Test;

my $prompt = "sdb> ";

sub new {
    my $state = {};
    $state->{"sdb"} = $_[1];
    $state->{"cmd"} = {};
    $state->{"auto_print"} = 1;

    # add the commands from the various modules
    add_commands($state->{"cmd"}); # this pkg has commands too
    SDBUTIL::CMD::Domains::add_commands($state->{"cmd"});
    SDBUTIL::CMD::Test::add_commands($state->{"cmd"});
    # merge ($state->{"cmd"}, \%SDBUTIL::CMD::Domains::cmds);
    return bless $state;
}

sub results_to_string {
    my $state = shift;
    my @results;
    my $ret = "";
    if ($#_ < 0) {
        @results = @{$state->{"last_results"}};
    } else {
        @results = @_;
    }
    for my $r (@results) {
        $ret .= "$r\n";
    }
    return $ret;
}

sub print_results {
    my $state = shift;
    print $state->results_to_string(@_);
}

sub run {
    my $state   = $_[0];
    my $cmd_tab = $state->{"cmd"};
    my $term    = new Term::ReadLine 'sdbutil';
    my $ret;

    while ( defined ($_ = $term->readline($prompt)) ) {
        # get first word and look it up in the command table
        ($cmd, $args) = split /\s/, $_, 2;
        # ignore commands that consist of only white space
        if(!($cmd =~ /\S/)) {
            next;
        }
        if (defined $cmd_tab->{$cmd} && ref $cmd_tab->{$cmd} eq "CODE") {
            # pass the rest of the line to the command
            $ret = &{$cmd_tab->{$cmd}}($state, $args);
            # commands will return undef if they need to quite
            if (!defined $ret) {
                # command wants to quit
                last;
            }
            $state->{"last_results"} = $ret;
            if ($state->{"auto_print"}) {
                $state->print_results();
            }
        } else {
            print "Unknown command $cmd\n";
        }
    }
}

# repl based commands:
# print the last command output again (not does not execute it again)
sub print_again {
    my $state = $_[0];

    return $state->{'last_results'}
}

sub list_commands {
    my $state = $_[0];
    my @cmds = keys(%{$state->{"cmd"}});

    return \@cmds;
}

sub quit {
    return undef;
}

sub add_commands {
	my $cmds = $_[0];

	$cmds->{"g"} = \&print_again;
	$cmds->{"list_commands"} = \&list_commands;
	$cmds->{"quit"} = \&quit;
	$cmds->{"exit"} = \&quit;
	$cmds->{"x"} = \&quit;
}