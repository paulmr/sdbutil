package SDBUTIL::Data::Response::Item;

use strict;

sub get_row {
	my $self = shift;
	return $self;
}

sub new {
	my $self = $_[1];
	return bless($self, $_[0]);
}

package SDBUTIL::Data::Response::ItemString;

our @ISA = ("SDBUTIL::Data::Response::Item");

sub to_string {
	my $self = shift;
	return join("", @{$self});
}

sub new {
	my $self = $_[1];
	return bless([$self], $_[0]);
}

package SDBUTIL::Data::Response::DataRow;

our @ISA = ("SDBUTIL::Data::Response::Item");

sub new {
	my ($classname, $item) = @_;
	my $self = {};
	my $attributes = $item->{'Attribute'};

	# it's possible that attributes is actually just a single hash, if there is
	# only one result -- in that case put it into an array
	if (ref $attributes ne "ARRAY") {
		$attributes = [$attributes];
	}

	$self->{'name'} = $item->{'Name'};
	$self->{'data'} = {};
	$self->{'data'}->{'itemName'} = $self->{'name'};
	for (@$attributes) {
		my ($key, $val) = ($_->{'Name'}, $_->{'Value'});
		$self->{data}->{$key} = $val;
	}
	return bless($self, $classname);
}

sub get_row {
	my $self   = shift;
	my @fields = @_;
	my @ret;
	if (scalar @fields < 1) {
		@fields = sort keys %{$self->{'data'}};
	} elsif (ref $fields[0] eq "ARRAY") {
		@fields = @{$fields[0]};
	}
	# return an array of values, getting the keys provided or in the order
	# provided (or simply al keys sorted otherwise)
	for (@fields) {
		if (defined $self->{data}->{$_}) {
			push @ret, $self->{data}->{$_};
		} else {
			push @ret, "NULL";
		}
	}
	return \@ret;
}

sub get_keys {
	my $self = shift;
	return [ keys %{$self->{'data'}} ];
}

package SDBUTIL::Data::Response;

# each item may be of a different response

sub get_row {
	my $self = shift;

	if ($self->{cur_row} > $#{$self->{response}}) {
		# finished
		return undef;
	} else {
		return $self->{response}->[$self->{cur_row}++]->get_row(@_);
	}
}

# bless the provided array ref as the provided class
sub new {
	my ($i, $classname, $ref) = (0, $_[0], $_[1]);
	my $itemClass = $_[2] || 'SDBUTIL::Data::Response::Item';

	my $self = {};

	if (ref $ref ne "ARRAY") {
		return undef;
	}

	# for each item in the array, work out what it is, and create an
	# appropriate response item object
	for ($i = 0; $i <= $#{$ref}; $i++) {
		# the default, just convert it to a scalar reference
		$ref->[$i] = $itemClass->new($ref->[$i]);
	}

	$self->{response} = $ref;
	$self->{isdata}   = 0;
	$self->{istable}  = 0;
	$self->{cur_row}  = 0;
	return bless($self, $classname);
}

package SDBUTIL::Data::ResponseError;

our @ISA = ("SDBUTIL::Data::Response");

sub to_string {
	my $self = shift;
	return join("\n", (map {
			$_->to_string();
		} @{$self->{'response'}}));
}

sub new {
	my $self = SDBUTIL::Data::Response->new($_[1], "SDBUTIL::Data::Response::ItemString");
	return bless($self, $_[0]);
}

1;
