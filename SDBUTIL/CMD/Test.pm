package SDBUTIL::CMD::Test;

use strict;

sub test {
	my $state = $_[0];
	my $ret = [];

	push @{$ret}, "args: " . $_[1];
	push @{$ret}, "<test_ret_array>";
	print "test created ret array: ", $#{$ret}, "\n";
	return $ret;
}

sub add_commands {
	my $cmds = $_[0];

	$cmds->{"test"} = \&test;
}

1;
