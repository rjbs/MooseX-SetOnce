use strict;
use warnings;
use Test::More;
use Test::Fatal;

use lib 'lib';
require MooseX::SetOnce;

{
  package Apple;
  use Moose;

  has color => (
    is     => 'rw',
    traits => [ qw(SetOnce) ],
  );
}

{
  package Orange;
  use Moose;

  has color => (
    reader => 'get_color',
    writer => 'set_color',
    traits => [ qw(SetOnce) ],
  );
}

for my $set (
  [ Apple   => qw(    color     color) ],
  [ Orange  => qw(get_color set_color) ],
) {
  my ($class, $getter, $setter) = @$set;
  my $object = $class->new;

  {
    is(
      exception { $object->$setter('green'); },
      undef,
      "can set a SetOnce attr once",
    );

    is($object->$getter, 'green', "it has the first value we set");
  }

  {
    like(
      exception { $object->$setter('blue'); },
      qr{cannot change value.+\bcolor\b},
      "can't set a SetOnce attr twice (via $setter)",
    );
    is($object->$getter, 'green', "it has the first value we set");
  }

  {
    like(
      exception {
        $object->meta->get_attribute('color')->set_value($object, 'yellow');
      },
      qr{cannot change value.+\bcolor\b},
      "can't set a SetOnce attr twice (via set_value)",
    );
    is($object->$getter, 'green', "it has the first value we set");
  }
}

done_testing;
