use strict;
use warnings;
package MooseX::Worm;
# ABSTRACT: write-once, read-many attributes for Moose

=head1 SYNOPSIS

Add the "Worm" trait to attributes:

  package Class;
  use Moose;
  use MooseX::Worm;

  has some_attr => (
    is     => 'rw',
    traits => [ qw(Worm) ],
  );

...and then you can only set them once:

  my $object = Class->new;

  $object->some_attr(10);  # works fine
  $object->some_attr(20);  # throws an exception: it's already set!

=head1 DESCRIPTION

The 'Worm' attribute lets your class have attributes that are not lazy and not
set, but that cannot be altered once set.

The logic is very simple:  if you try to alter the value of an attribute with
the Worm trait, either by accessor or writer, and the attribute has a value, it
will throw an exception.

If the attribute has a clearer, you may clear the attribute and set it again.

=cut

package MooseX::Attribute::Trait::Worm;
use Moose::Role 0.90;

before set_value => sub { $_[0]->_ensure_unset($_[1]) };

sub _ensure_unset {
  my ($self, $instance) = @_;
  Carp::confess("cannot change value of Worm attribute")
    if $self->has_value($instance);
}

around accessor_metaclass => sub {
  my ($orig, $self, @rest) = @_;

  return Moose::Meta::Class->create_anon_class(
    superclasses => [ $self->$orig(@_) ],
    roles => [ 'MooseX::Worm::Accessor' ],
    cache => 1
  )->name
};

package MooseX::Worm::Accessor;
use Moose::Role 0.90;

around _inline_store => sub {
  my ($orig, $self, $instance, $value) = @_;

  my $code = $self->$orig($instance, $value);
  $code = sprintf qq[%s->meta->get_attribute("%s")->_ensure_unset(%s);\n%s],
    $instance,
    quotemeta($self->associated_attribute->name),
    $instance,
    $code;

  return $code;
};

package Moose::Meta::Attribute::Custom::Trait::Worm;
sub register_implementation { 'MooseX::Attribute::Trait::Worm' }

1;
