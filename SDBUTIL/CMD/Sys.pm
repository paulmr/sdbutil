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

# set the output file for data
sub out {
	my ($state, $fname) = @_;

	if (defined $state->{"DATA_OUTF"}) {
		die SDBUTIL::Data::ResponseError->new([ "a file is already open for output" ]);
	}

	if (!open(DATA_OUTF, ">", $fname)) {
		die SDBUTIL::Data::ResponseError->new([ "could not open file $fname" ]);
	}

	$state->{"DATA_OUTF"} = \*DATA_OUTF;
	return SDBUTIL::Data::Response->new([ "Data will be output to $fname" ]);
}

sub add_commands {
	my $cmds = $_[0];

	$cmds->{"set"} = \&set;
	$cmds->{"out"} = \&out;
}

1;
