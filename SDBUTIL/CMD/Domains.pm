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

# selects a database to use for future commands, or prints the current if no arg
# provided
sub use {
	my ($state, $db) = @_;

	$db =~ s/^\s*//;
	$db =~ s/\s*$//;

	if ($db && length($db) > 0) {
		$state->{"SELECTED_DOMAIN"} = $db;
	}
	return ["Selected domain: " .
		($state->{"SELECTED_DOMAIN"} ?
			$state->{"SELECTED_DOMAIN"} : "none")];
}

sub add_commands {
	my $cmds = $_[0];

	$cmds->{"list_domains"} = $cmds->{"ls"} = \&list;
	$cmds->{"use"} = \&use;
}

1;
