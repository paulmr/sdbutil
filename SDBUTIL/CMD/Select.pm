package SDBUTIL::CMD::Select;

# the basic select statment, just sends it's argument directly to aws
#
sub cmd_select {
	my ($state, $stmt) = @_;
	# the rows will be built up here (i.e. if we have to do multiple requests in
	# order to get all of them)
	my $rows = [];
	my $sdb = $state->{"sdb"};
	$state->{"RowCount"}  = 0;
	my $next = undef;
	do {
		# we were given a pre-formed statement object to send
		my $req;
		if (ref $stmt eq "HASH") {
			$req = $stmt;
		} else {
			if ($stmt !~ m/^select/) {
				$stmt = "select $stmt";
			}
			$req = { SelectExpression => $stmt };
			$req->{'NextToken'} = $next if $next;
		}

		$state->{last_select} = $req->{SelectExpression};
		my $ret = $sdb->send_request('Select', $req)->{'SelectResult'};

		if (exists($ret->{"NextToken"})) {
			$state->{"NextToken"} = $ret->{"NextToken"};
			# put the next token in for the next request
			$next = $ret->{"NextToken"};
		} else {
			$state->{"NextToken"} = $next = undef;
		}
		$state->{"RowCount"}  += (scalar @{$ret->{"Item"}});
		push @$rows, @{$ret->{"Item"}};
	} while($state->get_opt('autonext') && $next);

	if ($state->get_opt("verbose")) {
		print "Row count: ", $state->{"RowCount"}, "\n";
	}
	my $response = SDBUTIL::Data::Response->new($rows,
		"SDBUTIL::Data::Response::DataRow");
	$response->{'istable'} = 1;
	$response->{'isdata'}  = 1;
	return $response;
}

# just send the next token (if there is one) and return the results, if there
# are any
sub cmd_next {
	my $state = shift;
	if ($state->{"NextToken"}) {
		return cmd_select $state, {
			NextToken        => $state->{NextToken},
			SelectExpression => $state->{last_select},
		};
	}
	return SDBUTIL::Data::Response->new([ "No more and then" ],
		"SDBUTIL::Data::Response::ItemString");
}

# prints out the field names from the selected results
sub cmd_describe {
	my $state = shift;
	my $stmt = bld_select($state, fields => ['*']);
	my $results = cmd_select($state, $stmt);
	my %fields;
	for (@{$results->{response}}) {
		for $key (@{$_->get_keys}) {
			if (defined $fields{$key}) {
				$fields{$key} += 1;
			} else {
				$fields{$key} = 1;
			}
		}
	}
	return SDBUTIL::Data::Response->new([ keys %fields ], "SDBUTIL::Data::Response::ItemString");
	return $results;
}

# takes names args as a hash and uses them to build an appropriate select
# statement, using sensible defaults for missing args, and then returning it as
# a string
sub bld_select {
	my $state = shift;
	my %args = @_;
	my @ret = ("select");
	if ($args{'fields'}) {
		push @ret, join(",", @{$args{'fields'}});
	} elsif (%{$state->{"fields"}}) {
		push @ret, join(",", keys %{$state->{"fields"}});
	} else {
		push @ret, "*";
	}

	push @ret, "from";
	if ($args{'domain'}) {
		push @ret, "`" . $args{'domain'} . "`";
	} elsif ($state->{"SELECTED_DOMAIN"}) {
		push @ret, "`" . $state->{"SELECTED_DOMAIN"} . "`";
	} else {
		die SDBUTIL::Data::ResponseError->new(["No selected domain"]);
	}

	if ($args{'where'}) {
		push @ret, "where", $args{'where'};
	}
	return join(" ", @ret);
}

# shortcut select -> just uses current table, current fields and returns
# everything

sub cmd_sel {
	my $state = shift;
	my $sel = bld_select($state);
	return cmd_select($state, $sel);
}

# performs a select on the currently selected table/domain, using the current
# field list, adding a where clause
sub cmd_where {
	my ($state, $where) = @_;
	my $sel;
	if (!$where) {
		die SDBUTIL::Data::ResponseError->new(["No argument provided"])
	}
	$sel = bld_select($state, where => $where);
	return cmd_select($state, $sel);
}

sub cmd_count {
	my $state = shift;
	my $sel = bld_select($state, fields => ["count(*)"]);
	return cmd_select($state, $sel);
}

##### WIP
#sub describe {
#	# list the column names
#	format DESCRIBE =
#@<<<<<<<<<<<<<<<<<<<<<<<< : @######
#$name, $count
#.
#	
#}

sub add_commands {
	my $cmds = $_[0];

	$cmds->{"select"} = \&cmd_select;
	$cmds->{"sel"}    = \&cmd_sel;
	$cmds->{"desc"}   = \&cmd_describe;
	$cmds->{"next"}   = \&cmd_next;
	$cmds->{"where"}  = \&cmd_where;
	$cmds->{"count"}  = \&cmd_count;
}

1;
