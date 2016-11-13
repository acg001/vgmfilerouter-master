#!/usr/bin/perl
#
# Description: The purpose of this module is to find files
# without recursing through the subfolders
# Public functions:
# 1. ListFiles - Input:  folder to work on
#                Output: Array of files found
# Version Control
# Ver   Date      Description                    Changed by
# 1.0   20161006  Initial Release                ACG001
#

package InttraFtp::TpFiles;

use strict;
use warnings;
use File::Find;
use File::Spec;

my @files;
my $max_age_file=10;

sub import{
   no strict 'refs'; # Allow typeglobs
   my $pkg=caller 0; # Get the name of the calling package
   foreach my $sym(qw(ListFiles FileType MakeDir)) {
      *{"${pkg}::$sym"} = \&$sym;  # put a reference to the symbol
                                   # on the user's symbol table
   }
}

###############
sub ListFiles {
###############
   my $dir=shift;
   undef @files;
   find ({ wanted     => \&search,
        preprocess => \&filter_dirs,
   }, $dir);
   return @files;
}

sub search {
   if (-f $_) {
      push @files,$File::Find::name;
   }
}

sub filter_dirs
{
    my @inlist = @_;
    my @outlist;

    foreach (@inlist)
    {
        push @outlist, $_ if ! -d $_;
    }
    return @outlist;
}

sub FileAge {
   my $ref_file=shift;
   my $ref_max_age=shift;
   my @foundfiles;
   my @errorlist;

   $max_age_file=${$ref_max_age} if ${$ref_max_age};
   my $FILE_AGE=time-(stat(${$ref_file}))[9];

   if (${$ref_file}) {
      if($FILE_AGE > $max_age_file) {
         push @foundfiles,"${$ref_file}";
      }
   } else {
      push @errorlist,"${$ref_file} not found.";
   }
   return \@foundfiles,\@errorlist;
}
##############
sub FileType {
##############
   my $ref_filepath=shift;
   my $file_to_check=${$ref_filepath};
   my @errorlist;

   # MSGTYPE
   # 0 = xml 
   # 1 = edifact
   # 9 = unknkown

   if ( ! -e $file_to_check ) {
      push @errorlist,"Error-InttraFtp:TpFiles:FileType-${file_to_check} does not exist";
   }

   # Is XML or EDI - default is EDI = 1
   ####################################
   my $MSGTYPE=9;

   open (my $fhandler, "<", $file_to_check);

   my $line_count=0;
   foreach my $_header (<$fhandler>) {
   my $lines=$.;
      last if ( $line_count == $lines );
      if ( $_header=~/(^\s*\<)/) {
         $MSGTYPE=0;
         last;
      } elsif ( $_header=~/^(\s*)UNA|^(\s*)UNB/ ) {
         $MSGTYPE=1;
         last; 
      } elsif ( $_header!~/\w+/ ) {
         $line_count++;
         next; 
      } else {
         $line_count++;
         last;
      }
   }

   close $fhandler if $fhandler;
   return \$MSGTYPE,\@errorlist;

}

#############
sub MakeDir {
#############
   my $dirpath;
   my @msgs;
   my $refdir=shift;
   my @arcdirs = File::Spec->splitdir(${refdir});
   foreach my $i (1..$#arcdirs) {
      $dirpath="$dirpath/$arcdirs[$i]";
      next if ( $i < 3 );
      push @msgs,"TpFile:MakeDir Path to create: $dirpath";
      if ( -e $dirpath and -d $dirpath ) {
         push @msgs,"Dir $dirpath exists. Skipping...";
      } else {
         push @msgs,"TpFile:MakeDir $dirpath does not exist. Creating...\n";
         unless ( -e "$dirpath" or mkdir("$dirpath",0775) ) {
            push @msgs,"$!";
            push @msgs,"Unable to create $dirpath";
            return (1,\@msgs);
         }
      }
   }
   return 0,\@msgs;
}

1;
