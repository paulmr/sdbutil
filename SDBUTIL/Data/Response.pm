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
	for (@$attributes) {
		my ($key, $val) = ($_->{'Name'}, $_->{'Value'});
		$self->{data}->{$key} = $val;
	}
	return bless($self, $classname);
}

sub get_row {
	my $self = shift;
	my @ret;
	# return an array of values, sorted by the key
	for (sort keys %{$self->{'data'}}) {
		push @ret, $self->{data}->{$_};
	}
	return \@ret;
}

package SDBUTIL::Data::Response;

# each item may be of a different response

sub get_row {
	my $self = shift;

	if ($self->{cur_row} > $#{$self->{response}}) {
		# finished
		return undef;
	} else {
		return $self->{response}->[$self->{cur_row}++]->get_row();
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
	$self->{isdata} = 0;
	$self->{istable} = 0;
	$self->{cur_row} = 0;
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
