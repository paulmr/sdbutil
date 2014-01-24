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

# these are resonsible for taking an array of values and an array of field names
# and outputting them

sub fmt_card {
	my ($names, $vals, $state) = @_;
	my $ret = "";
	for (my $i = 0; $i <= $#{$names}; $i++) {
		$ret .= sprintf("%s: %s%s",
			$names->[$i], $vals->[$i], $state->get_opt("card_field_sep"));
	}
	return $ret;
}

sub fmt_csv {
	my ($names, $vals, $state) = @_;
	return join($state->get_opt("csv_field_sep"), @$vals);
}

our %DATA_ROW_FORMATTERS = (
	card => \&fmt_card,
	csv  => \&fmt_csv
);

sub to_string {
	my ($self, $state) = @_;
	return $DATA_ROW_FORMATTERS{$state->get_opt("format")}->($self->{'names'},
		$self->{'vals'}, $state);
}

sub new {
	my ($class, $response) = @_;
	my $self = {};
	# this is now an array of hash refs
	$self->{'vals'}     = [];
	$self->{'names'}   = [];
	for (my $i = 0; $i <= $#{$response->{"Attribute"}}; $i++) {
		push @{$self->{'vals'}},  $response->{"Attribute"}->[$i]->{'Value'};
		push @{$self->{'names'}}, $response->{"Attribute"}->[$i]->{'Name'};
	}
	$self->{'ItemName'} = $response->{"Name"};
	return bless($self, $class);
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
