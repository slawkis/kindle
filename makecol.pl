#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use File::Find;
use Digest::SHA1 qw(sha1_hex);
use File::Spec;
use Data::Dumper;
use Image::ExifTool qw(:Public);
use Cwd;

########## 
########## CONFIG
########## 

#my $path = '/run/media/steev/Kindle';
my $path = '.';
my @ebook = ( 'mobi', 'azw', 'azw1', 'azw2', 'azw3', 'pdf', 'txt');

########## 
########## CODE
########## 

my %ebook;
my %collection;
my %exif;
my @files;
my @path;
my $colname;
my $sha1;
my $file;
my $book;
my $prefix='/mnt/us';
my $time = time();
my $cnt;

sub doArray($) {
    my $fname = $File::Find::name;
    
    my @parts = split(/\./,$fname);
    my $ext=pop @parts;
    print "> $fname ".getcwd()." \n";
#    print "$fname \n" if -f "$fname";
    push @files,"$fname" if exists $ebook{$ext};
#    print "< $fname \n";

}

sub getAsin($) {
    my $file = shift;
    my $asin;
    %exif=%{ImageInfo($file)};
    $asin=$exif{'ASIN'};
    if (defined $asin) {  return ("#".${asin}."^EBOK"); } else {return undef;}
#    open ASIN,"ebook-meta \"$file\" |" or die;
#    $asin = join "",<ASIN>;
#    close ASIN;
#    if ($asin=~/asin:(.+)\n/m) { return ("#".$1."^EBOK"); } else {return undef;}
}


chdir $path;
map { $ebook{$_}=1 } @ebook;
find (\&doArray,$path);

#print Dumper @files;
#exit;

$cnt=scalar(@files);
#print Dumper @files;
for $file (@files) {
     printf STDERR "\r%4d",$cnt--;
#    next unless $file=~/Net/;
    @path=File::Spec->splitdir($file);
#print Dumper  \@path;
    pop @path;
    $colname = pop @path;
    $colname =~ y/_/ /;
    $book=$file;
    $book=~s|^${path}(.*)$|${prefix}$1|;
    $sha1= getAsin($file);
    $sha1= "*".sha1_hex($book) if not defined $sha1;
#    print "$book\n";
    push@{$collection{$colname}},$sha1;
#    print "$colname : $book\n";
}
    print STDERR "\rDone.\n\n";

#print Dumper @files;

#print Dumper \%collection;
#exit;

open JSON,">collections.json" or die;
    print JSON "{\n";
    for $colname (sort keys %collection) {
	next if $colname =~ 'documents';
	@files = @{$collection{$colname}};
	print JSON " \"${colname}\@pl-PL\": {\n  \"items\": [\n";
	map { $_="    \"$_\"";} @files;
	print JSON join(",\n",@files);
	print JSON "\n  ], \"lastAccess\": $time\n },\n";
	$time--;
    }
    print JSON "}";
close JSON;

