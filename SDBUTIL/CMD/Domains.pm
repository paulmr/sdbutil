# contains implentations for commands related to domains
#

package SDBUTIL::CMD::Domains;

use strict;
use SDBUTIL::Data::Response;

sub create_domain {
	my ($state, $domainName) = @_;
	my $sdb = $state->{'sdb'};

	my $ret = $sdb->send_request('CreateDomain', { DomainName => $domainName });
	return SDBUTIL::Data::Response->new([ "done" ], "SDBUTIL::Data::Response::ItemString");
}

# list the domains, each element in the return array has one domain name
#
sub list {
	my $state = $_[0];
	my $sdb = $state->{'sdb'};

	my $ret = $sdb->send_request('ListDomains');

	return SDBUTIL::Data::Response->new($ret->{'ListDomainsResult'}->{'DomainName'},
		"SDBUTIL::Data::Response::ItemString");
}

# selects a database to use for future commands, or prints the current if no arg
# provided
sub use {
	my ($state, $db) = @_;

	if ($db && $db =~ m/\S/) {
		$db =~ s/^\s*//;
		$db =~ s/\s*$//;

		$state->{"SELECTED_DOMAIN"} = $db;
	}
	return SDBUTIL::Data::Response->new(["Selected domain: " .
			($state->{"SELECTED_DOMAIN"} ?
			$state->{"SELECTED_DOMAIN"} : "none")],
			"SDBUTIL::Data::Response::ItemString");
}

sub add_commands {
	my $cmds = $_[0];

	$cmds->{"create"} = \&create_domain;
	$cmds->{"list_domains"} = $cmds->{"ls"} = \&list;
	$cmds->{"use"} = \&use;
}

1;
