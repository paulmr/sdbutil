package SDBUTIL::Data::Response::Item;

use strict;

sub to_string {
	my $self = $_[0];
	my $_self = ${ $self };
	return "$$self";
}

sub new {
	my $self = $_[1];
	return bless \$self;
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

sub new {
	my ($i, $ref) = (0, $_[1]);
	if (ref $ref ne "ARRAY") {
		return undef;
	}

	# for each item in the array, work out what it is, and create an
	# appropriate response item object
	for ($i = 0; $i <= $#{$ref}; $i++) {
		# the default, just convert it to a scalar reference
		$ref->[$i] = SDBUTIL::Data::Response::Item->new($ref->[$i]);
	}
	return bless $ref;
}

1;
