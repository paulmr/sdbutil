#!/usr/bin/perl
#

package SDBUTIL::Repl;

use Term::ReadLine;
use SimpleDB::Client;
use Exception::Class;
use Try::Tiny;
use SDBUTIL::CMD::Domains;
use SDBUTIL::CMD::Select;
use SDBUTIL::CMD::Sys;
use SDBUTIL::CMD::Test;

my $prompt = "sdb> ";

sub new {
    my $state = {};
    $state->{"sdb"} = $_[1];
    $state->{"cmd"} = {};
    $state->{"opt"} = {
        auto_print     => 1,
        card_field_sep => "\n",
        csv_field_sep  => ",",
        rec_sep        => "\n",
        format         => "card",
        verbose        => 1,
    };

    # add the commands from the various modules
    add_commands($state->{"cmd"}); # this pkg has commands too
    SDBUTIL::CMD::Domains::add_commands($state->{"cmd"});
    SDBUTIL::CMD::Sys::add_commands($state->{"cmd"});
    SDBUTIL::CMD::Select::add_commands($state->{"cmd"});
    SDBUTIL::CMD::Test::add_commands($state->{"cmd"});
    # merge ($state->{"cmd"}, \%SDBUTIL::CMD::Domains::cmds);
    return bless $state;
}

sub get_opt {
    my ($state, $opt_name) = @_;
    return $state->{"opt"}->{$opt_name};
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
        $ret .= $r->to_string($state) . $state->get_opt("rec_sep");
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
            eval { $ret = &{$cmd_tab->{$cmd}}($state, $args); };
            # check for error
            if ($@) {
                warn $@;
                $ret = []; # give it the default empty array ref
            }
            # commands will return undef if they need to quit
            if (!defined $ret) {
                # command wants to quit
                last;
            }
            $state->{"last_results"} = $ret;
            if ($state->get_opt("auto_print")) {
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
