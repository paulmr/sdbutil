package SDBUTIL::Data::Response::Item;

use strict;

sub to_string {
	my $self = $_[0];
	return "$$self";
}

sub new {
	my ($class, $self) = @_;
	# if it is not already a reference, convert it to one
	return bless (((ref $self) ? $self : \$self), $class);
}

package SDBUTIL::Data::Response::DataRow;

our @ISA = ("SDBUTIL::Data::Response::Item");

sub to_string {
	my $self = $_[0];
	my $row = %$self;
	return join(",", keys %$self);
}

package SDBUTIL::Data::Response;

# each item may be of a different response

sub to_string {
	my ($i, $self) = (0, $_[0]);

	my $ret = "";

	for(; $i <= $#{$self}; $i++) {
		$ret .= ($self->[$i]->to_string() . "\n");
	}
	return $ret;
}

# bless the provided array ref as the provided class
sub new {
	my ($i, $ref) = (0, $_[1]);
	my $itemClass = $_[2] || 'SDBUTIL::Data::Response::Item';

	if (ref $ref ne "ARRAY") {
		return undef;
	}

	# for each item in the array, work out what it is, and create an
	# appropriate response item object
	for ($i = 0; $i <= $#{$ref}; $i++) {
		# the default, just convert it to a scalar reference
		$ref->[$i] = $itemClass->new($ref->[$i]);
	}
	return bless $ref;
}

1;
