# contains implentations for commands related to this system itself, e.g.
# setting options etc
#

package SDBUTIL::CMD::Sys;

use strict;
use SDBUTIL::Data::Response;

# list the domains, each element in the return array has one domain name
#
sub set {
	my $state = shift;
	if ($#_ < 0 || !$_[0]) {
		return SDBUTIL::Data::Response->new(["nothing to do"],
			"SDBUTIL::Data::Response::ItemString");
	}
	my ($var, $val) = split(/\s*=\s*/,shift);
	if (!defined $state->{"opt"}->{$var}) {
		die SDBUTIL::Data::ResponseError->new([ "Unknown option $var" ]);
	} else {
		if (!defined $val) {
			return SDBUTIL::Data::Response->new([ "$var is " .
				$state->{"opt"}->{$var}], "SDBUTIL::Data::Response::ItemString");
		} else {
			$state->{"opt"}->{$var} = $val;
			return SDBUTIL::Data::Response->new([ "$var set to $val" ],
				"SDBUTIL::Data::Response::ItemString");
		}
	}
}

sub field {
	my $state = shift;
	# if we have an arg, modify the list accordingly; either way print current
	# status at the end
	if ($#_ >= 0 && $_[0]) {
		my @fields = split(/\s/, $_[0]);
		for (@fields) {
			my $cmd;
			if (/^([+-])/) {
				$cmd = $1;
				$_ = substr($_, 1);
			} else {
				$cmd = "+";
			}
			if ($cmd eq "+") {
				$state->{'fields'}->{$_} = 1;
			} else {
				delete($state->{'fields'}->{$_});
			}
		}
	}
	my @fields = keys $state->{'fields'};
	return SDBUTIL::Data::Response->new(\@fields,
		"SDBUTIL::Data::Response::ItemString");
}

# set the output file for data
sub out {
	my ($state, $fname) = @_;

	if (!$fname) {
		my $ret = ( $state->{out_filename} || "No output file" );
		return SDBUTIL::Data::Response->new([ $ret ], "SDBUTIL::Data::Response::ItemString");
	}

	if ($fname eq "-") {
		undef $state->{out_filename};
		close $state->{DATA_OUTF};
		$state->{DATA_OUTF} = \*STDOUT;
		return SDBUTIL::Data::Response->new([ "Resetting output file to STDOUT" ],
			"SDBUTIL::Data::Response::ItemString");
	}

	if ($state->{out_filename}) {
		die SDBUTIL::Data::ResponseError->new([ "a file is already open for output" ]);
	}

	if (!open(DATA_OUTF, ">", $fname)) {
		die SDBUTIL::Data::ResponseError->new([ "could not open file $fname" ]);
	}

	$state->{DATA_OUTF}  = \*DATA_OUTF;
	$state->{out_filename} = $fname;
	return SDBUTIL::Data::Response->new([ "Data will be output to $fname" ],
		"SDBUTIL::Data::Response::ItemString");
}

sub add_commands {
	my $cmds = $_[0];

	$cmds->{"set"} = \&set;
	$cmds->{"out"} = \&out;
	$cmds->{"field"} = \&field;
}

1;
