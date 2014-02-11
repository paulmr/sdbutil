#!/usr/bin/perl
#

package SDBUTIL::Repl;

use Term::ReadLine;
use SimpleDB::Client;
use Text::CSV;
use SDBUTIL::CMD::Domains;
use SDBUTIL::CMD::Select;
use SDBUTIL::CMD::Sys;
use SDBUTIL::CMD::Test;

my $prompt = "sdb> ";

sub csv_table_formatter {
    my $state = shift;
    my $FH = shift;
    my $data = shift;
    my $csv = Text::CSV->new;
    $csv->print($FH, $data);
    print $FH "\n";
}

sub default_table_formatter {
    my $state = shift;
    my $FH = shift;
    my $data = shift;
    
    print $FH join ($state->get_opt('field_sep'),
        map { substr($_, 0, $state->get_opt('field_width')) } @$data),"\n";
}

sub default_sys_formatter {
    my $state = shift;
    my $FH = shift;
    my $data = shift;
    
    print $FH join("", @$data), "\n";
}


sub new {
    my $state = {};
    $state->{"sdb"} = $_[1];
    $state->{"cmd"} = {};
    $state->{"fields"} = {};
    $state->{"out_filename"} = "";
    $state->{DATA_OUTF} = \*STDOUT;

    # file descriptor, may point to a file in the future
    $state->{"opt"} = {
        auto_print    => 1,
        field_sep     => " | ",
        field_width   => 10,
        csv_field_sep => ",",
        rec_sep       => "\n",
        format        => "default",
        verbose       => 1,
        autonext      => 0,
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
    my $ret = "";
    for my $r (@{$_[0]}) {
        $ret .= $r->to_string($state) . $state->get_opt("rec_sep");
    }
    return $ret;
}

sub get_formatter {
    my $fmt = $_[0] . "_table_formatter";
    my $response = $_[1];

    if ($response->{'istable'}) {
        if (ref \&$fmt eq "CODE") {
            return \&$fmt;
        } else {
            print STDERR "Unknown format: $_[0]\n";
            return \&default_formatter;
        }
    } else {
        return \&default_sys_formatter;
    }
}

sub print_response {
    my $state = shift;
    my $response = shift;
    my $fmt = get_formatter($state->get_opt("format"), $response);
    my $FH = ($response->{isdata}) ? $state->{DATA_OUTF} : \*STDOUT;
    while (defined (my $row = $response->get_row())) {
        &{$fmt}($state, $FH, $row);
    }
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
        if(!$cmd || !($cmd =~ /\S/)) {
            next;
        }
        if (defined $cmd_tab->{$cmd} && ref $cmd_tab->{$cmd} eq "CODE") {
            # pass the rest of the line to the command
            eval { $ret = &{$cmd_tab->{$cmd}}($state, $args); };
            # check for error
            if ($@) {
                if ($@->isa("SDBUTIL::Data::ResponseError")) {
                    print STDERR "Error: " . $@->to_string(). "\n";
                } else {
                    warn $@;
                }
                $ret = SDBUTIL::Data::Response->new([]); # give it the default empty array ref
            }
            # commands will return undef if they need to quit
            if (!defined $ret) {
                # command wants to quit
                last;
            }
            $state->{"last_results"} = $ret;
            if ($state->get_opt("auto_print")) {
                $state->print_response($ret);
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
