package SDBUTIL::CMD::Select;

# the basic select statment, just sends it's argument directly to aws
#
sub select {
	my ($state, $stmt) = @_;
	my $sdb = $state->{"sdb"};

	my $ret = $sdb->send_request('Select', { SelectExpression => 'select ' . $stmt });
	$ret = $ret->{'SelectResult'};
	$state->{"NextToken"} = $ret->{"NextToken"};
	$state->{"RowCount"}  = $#{$ret->{"Item"}} + 1;
	if ($state->get_opt("verbose")) {
		print "Row count: ", $state->{"RowCount"}, "\n";
	}
	return SDBUTIL::Data::Response->new($ret->{"Item"}, "SDBUTIL::Data::Response::DataRow");
}

sub add_commands {
	my $cmds = $_[0];

	$cmds->{"select"} = \&select;
}

1;
