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
		return SDBUTIL::Data::Response->new([ "Unknown option $var" ]);
	} else {
		if (!defined $val) {
			return SDBUTIL::Data::Response->new([ "$var is " .
				$state->{"opt"}->{$var}]);
		} else {
			$state->{"opt"}->{$var} = $val;
			return SDBUTIL::Data::Response->new([ "$var set to $val" ]);
		}
	}
}

sub add_commands {
	my $cmds = $_[0];

	$cmds->{"set"} = \&set;
}

1;
