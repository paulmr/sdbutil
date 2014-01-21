# contains implentations for commands related to domains
#

package SDBUTIL::CMD::Domains;

use strict;

# list the domains, each element in the return array has one domain name
#
sub list {
	my $state = $_[0];
	my $sdb = $state->{'sdb'};

	my $ret = $sdb->send_request('ListDomains');

	return $ret->{'ListDomainsResult'}->{'DomainName'};
}

sub add_commands {
	my $cmds = $_[0];

	$cmds->{"list_domains"} = \&list;
}

1;
