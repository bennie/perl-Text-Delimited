use Test::Simple tests => 27;
use strict;

use Text::Delimited;
ok(1); 

my $t = new Text::Delimited;
ok(defined $t);

### Change the delimiter

ok('|' eq  $t->Delimiter('|'));

### Open the file

ok($t->Open('t/test.txt'));

### Check the header row

my @head = $t->Fields;
ok(join(',',@head) eq 'col1,col2,col3');

### Read the first line

my $row = $t->Read;
ok(ref $row);

### Check the first line contents

ok(join(',', map {$row->{$_}} @head) eq 'foo,bar,baz');

### Read from various columns and check

for my $word ( qw/foo bar baz/ ) {
  my @letters = split '', $word;

  for my $num ( 1 .. 3 ) {
    $row = $t->Read;
    ok(ref $row);
    ok($row->{'col'.$num} eq shift @letters);
  }
}

### Check empty read

$row = $t->Read;
ok(not ref $row);

### close the file

ok($t->Close);
