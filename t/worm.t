use strict;
use warnings;
use Test::More;
use Try::Tiny;

use lib 'lib';
require MooseX::Worm;

{
  package Apple;
  use Moose;

  has color => (
    is     => 'rw',
    traits => [ qw(WORM) ],
  );
}

{
  package Orange;
  use Moose;

  has color => (
    reader => 'get_color',
    writer => 'set_color',
    traits => [ qw(WORM) ],
  );
}

for my $set (
  [ Apple   => qw(    color     color) ],
  [ Orange  => qw(get_color set_color) ],
) {
  my ($class, $getter, $setter) = @$set;
  my $object = $class->new;

  {
    my $error;
    my $died = try {
      $object->$setter('green');
      return;
    } catch {
      $error = $_;
      return 1;
    };

    ok( ! $died, "can set a WORM attr once") or diag $error;
    is($object->$getter, 'green', "it has the first value we set");
  }

  {
    my $error;
    my $died = try {
      $object->$setter('blue');
      return;
    } catch {
      $error = $_;
      return 1;
    };

    ok( $died, "can't set a WORM attr twice (via $setter)");
    is($object->$getter, 'green', "it has the first value we set");
  }

  {
    my $error;
    my $died = try {
      $object->meta->get_attribute('color')->set_value($object, 'yellow');
      return;
    } catch {
      $error = $_;
      return 1;
    };

    ok( $died, "can't set a WORM attr twice (via set_value)");
    is($object->$getter, 'green', "it has the first value we set");
  }
}

done_testing;
