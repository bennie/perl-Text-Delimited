=head1 NAME:

Text::Delimited - Module for parsing delimited text files

=head1 SYNOPSIS:

Text::Delimited provides a programattical interface to data stored in 
delimited text files. It is dependant upon the first row of the text 
file containing header information for each corresponding "column" in the 
remainder of the file.

After instancing, for each call to Read the next row's data is returned as 
a hash reference. The individual elements are keyed by their corresonding 
column headings.

=head1 USAGE:

A short example of usage is detailed below. It opens a pipe delimited file 
called 'infile.txt', reads through every row and prints out the data from 
"COLUMN1" in that row. It then closes the file.

  my $file = new Text::Delimited;
  $file->Delimiter('|');
  $file->Open('infile.tab');

  my @header = $file->Fields;

  while ( my $row = $file->Read ) {
    print $row->{COLUMN1}, "\n";
  }

  $file->Close;

The Close() method is atuomatically called when the object passes out of 
scope. However, you should not depend on this. Use Close() when 
approrpiate.

Other informational methods are also available. They are listed blow:

=head1 METHODS:

=item Close()

Closes the file or connection, and cleans up various bits.

=item Delimiter(delimiter)

Allows you to set the delimiter if a value is given. The default 
delimiter is a tab. Returns the delimiter.

=item Fields()

Returns an array (or arrayref, depending on the requested context) with 
the column header fields in the order specified by the source file.

=item FileName()

If Open was given a filename, this function will return that value.

=item LineNumber()

This returns the line number of the last line read. If no calls to Read 
have been made, will be 0. After the first call to Read, this will return 
1, etc.

=item new([filename|filepointer],[enumerate])

Creates a new Text::TabFile object. Takes optional parameter that is either
a filename or a globbed filehandle. Files specified by filename must 
already exist.

Can optionally take a second argument. If this argument evaluates to true,
TabFile.pm will append a _NUM to the end of all fields with duplicate names.
That is, if your header row contains 2 columns named "NAME", one will be 
changed to NAME_1, the other to NAME_2.

=item Open([filename|filepointer], [enumerate])

Opens the given filename or globbed filehandle and reads the header line. 
Returns 0 if the operation failed. Returns the file object if succeeds.

Can optionally take a second argument. If this argument evaluates to true,
TabFile.pm will append a _NUM to the end of all fields with duplicate names.
That is, if your header row contains 2 columns named "NAME", one will be 
changed to NAME_1, the other to NAME_2.

=item Read()

Returns a hashref with the next record of data. The hash keys are determined
by the header line. 

__DATA__ and __LINE__ are also returned as keys.

__DATA__ is an arrayref with the record values in order.

__LINE__ is a string with the original tab-separated record. 

This method returns undef if there is no more data to be read.

=item setMode(encoding)

Set the given encoding scheme on the tabfile to allow for reading files
encoded in standards other than ASCII.

=head1 EXPORTABLE METHODS:

For convienience, the following methods are exportable. These are handy 
for quickly writing output tab files.

=item tj(@STUFF)

Tab Join. Returns the given array as a string joined with tabs.

=item tl(@STUFF)

Tab Line. Returns the given array as a string joined with tabs (with 
newline appended).

=head1 AUTHORSHIP:

    Text::Delimited v1.93 2004/07/21

    (c) 2004, Phillip Pollard <bennie@cpan.org>
    Released under the Perl Artistic License

    Additional contributions by Kristina Davis <krd@menagerie.tf>
    Based upon the original module by Andrew Barnett <abarnett@hmsonline.com>

    Derived from Util::TabFile 1.9 2003/11/05
    With permission granted from Health Market Science, Inc.

=cut

package Text::Delimited;

use Symbol;

use 5.006;
use strict;

our $VERSION = '1.93';

### Private mthods

sub DESTROY {   
  return $_[0]->Close;
}

sub _line {
  my $self = shift @_;
  $self->{CURRENT_LINE} = readline($self->{FP});
  $self->{CURRENT_LINE} =~ s/[\r\n]+$//;
  $self->{CURRENT_DATA} = [ split /\Q$self->{DELIMITER}\E/o, $self->{CURRENT_LINE} ];
  $self->{LINE_NUMBER}++;
  return $self->{CURRENT_DATA};
}

### Public Methods

sub Close {
  my $self = shift @_;
  close $self->{FP} if $self->{FP};

  $self->{CURRENT_DATA} = $self->{CURRENT_LINE} = $self->{FILENAME} = 
  $self->{FP} = $self->{HDR} = $self->{LINE_NUMBER} = undef;

  return 1;
}

sub Delimiter {
  my $self = shift @_;
  my $new  = shift @_;

  if ( $new and $self->{LINE_NUMBER} > 0 ) {
    warn "You cannot change the delimiter after you have opened the file for processing.\n";
  } elsif ( $new ) {
    $self->{DELIMITER} = $new;
  }
    
  return $self->{DELIMITER};
}

sub Fields {
  my $self = shift @_;
  return wantarray ? @{$self->{HDR}} : $self->{HDR};
}

sub FileName {
  return $_[0]->{FILENAME};
}

sub LineNumber {
  return $_[0]->{LINE_NUMBER};
}

sub new {
  my $class = shift @_;
  my $file  = shift @_;
  my $enumerate = shift @_;

  my $self = {
    DELIMITER   => "\t",
    LINE_NUMBER => 0
  };
    
  bless $self, $class;

  $self->_init;

  my $status = $self->Open($file, $enumerate) if $file;
  
  return $self;
}

sub _init { }

sub Open {
    my $self = shift @_;
    my $file = shift @_;
    my $enumerate = shift @_;

    $self->{ENUMERATE} = $enumerate;

    if ( ref($file) eq 'GLOB' || not $file ) {
      $self->{FP} = $file || \*STDIN;
      $self->{FILENAME} = 'GLOB';
    } elsif ( -r $file ) {
      $self->{FP} = gensym;
      open $self->{FP}, $file or die "Can't open the file $file\n";
      $self->{FILENAME} = $file;
    } else {
      die "$file is neither a filehandle or an existing, readable file.";
    }

    $self->{HDR} = $self->_line;
  
    my %fields = ( );
    my %dupes = ( );
    for (my $i = 0; $i < scalar @{$self->{HDR}}; $i++) {
	my $field = ${$self->{HDR}}[$i];
	if ($fields{$field}) {
	    if ($self->{ENUMERATE} > 0) {
		$dupes{$field} += 1;
		${$self->{HDR}}[$i] = "$field\_$dupes{$field}";
	    }
	    else {
		die "ERROR: There is a duplicate column name: $field.  This is not good.\n";
	    }
	}
	$fields{$field} = 1;
    }
    return 1;
}

sub Read {
  my $self = shift @_;
  my $out  = {};

  my $data = $self->_line;

  return undef unless scalar @$data > 0;

  my $i = 0;
  for my $val ( @$data ) {
    $val =~ s/^\s+|\s+$//g;
    $out->{$self->{HDR}->[$i++]} = $val;
  }

  $out->{__DATA__} = $self->{CURRENT_DATA};
  $out->{__LINE__} = $self->{CURRENT_LINE};

  return $out;
}

sub setMode {
  my $self = shift @_;
  my $mode = shift @_;
  return binmode $self->{FP}, $mode;
}

### Exportable methods

sub d_join {
  if ( ref($_[0]) ) {
    my $self = shift @_;
    return join($self->{DELIMITER},@_);
  } else {
    return join("\t",@_);
  }
}

sub d_line {
  if ( ref($_[0]) ) {
    my $self = shift @_;
    return join($self->{DELIMITER},@_) . "\n";
  } else {
    return join("\t",@_);
  }
}

1;
