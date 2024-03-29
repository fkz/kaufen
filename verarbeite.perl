#!/usr/bin/perl


use strict;
use warnings;
use Date::Simple ('date');
use Products;

sub error {
  my ($line, $text) = @_;
  print STDERR "Fehler in Zeile $line: $text\n";
}

sub kategorie {
  my ($a, $b) = @_;
  my $a_ = Taxonomy::get $a;
  my $b_ = Taxonomy::get $b;
  $a_->category ($b_);
}

# Zeichen, die in einem Begriff auftreten dürfen
my $w = '[\wäöüÄÖÜ,!€\.%]+';

my %actual = (Ort => 'Unbekannt');

my $line = 0;
while (<>) {
  ++$line;
  if (/^\s*($w)\s*(:=|~|=)\s*($w)\s*$/) {
    if ($2 eq ':=')  {
      my $first = $1;
      my $second = $3;
      ($first !~ /^(Datum|Geschäft|Ort)$/) and error $line, "$first ist nicht definiert";
      if ($first eq 'Datum') {
	#parse date $second
	if ($second =~ /^(\d+)\.(\d+)\.(\d+)$/) {
	  $actual{$first} = date ($3 < 100 ? $3 + 2000 : $3, $2, $1);
	}
	else {
	  error $line, "Kein gültiges Datumsformat";
	}
      }
      else {
	$actual{$first} = $second;
      }
    }
    #synonym $3, $1 if $2 eq '=';
    kategorie $3, $1 if $2 eq '~';
  }
  elsif (/^\s*(($w\s+)*$w)\s*$/) {
    my @words = split /\s+/;
    
    my %article = (
      Ort => $actual{Ort},
      'Geschäft' => $actual{'Geschäft'}
    );
    
    my %props = ();
    
    for (@words) {
      if (/^(\d+,?\d*)€$/) {
	$article{Preis} = $1;
	$article{Preis} =~ s/,/\./;
      }
      elsif (/^(\d+,?\d*)(kg|g)$/) {
	$article{Gewicht} = $1;
	my $d2 = $2;
	$article{Gewicht} =~ s/,/\./;
	($d2 eq 'g') and ($article{Gewicht} /= 1000);
      }
      elsif (/^\d{5,13}$/) {
	$article{Code} = $_;
      }
      else {
	$article{Properties}->{$_} = 1;
      }
    }
    
    my $product = Product::get $article{Code};
    $product->setGewicht ($article{Gewicht}) if $article{Gewicht};
    for (keys %{$article{Properties}}) {
      $product->setAttribute ($_);
    }
    
    new Item ($product, $article{Preis}, $actual{Datum}, $actual{Ort}, 1, $actual{'Geschäft'}, undef);
  }
  else {
    /^\s*$/ or error $line, "$_ wurde nicht verarbeitet!";
  }
}

# erzeuge HTML-Dateien

mkdir "html";
chdir "html";


for (Item::list) {
  open my $fh, ">", $_->href;
   print $fh $_->html;
}

for (Product::list) {
  open my $fh, ">", $_->href;
  print $fh $_->html;
}


my $Preis = 0;

my %dates;
my %months;
my @all;

for (Item::list) {
  print $_->description;
  push @{$dates{$_->date}}, $_;
  push @{$months{$_->date->year . '-' . $_->date->month}}, $_;
  push @all, $_;
}

for (\%dates, \%months, { 'all' => \@all }) {
  my %d = %$_;
  for (keys %d) {
    open my $fh, ">", $_;
    print $fh Item::aggregate ("Produkte vom " . $_, "", @{$d{$_}});
  }
}

for (Taxonomy::list) {
  open my $fh, ">", $_->href;
  print $fh $_->html;
}

open my $index, ">", "index.html";
print $index <<HALLO
<?xml version="1.0" encoding="utf8" ?>
<!DOCTYPE html PUBLIC
  "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Produkte</title></head><body>
<a href='all'>Alle Produkte</a>
</body></html>
HALLO


#for (@articles) {
#  my %article = %$_;
#  my %attrs = %{$article{Properties}};
#  print "Artikel: $article{Code} (", (join ' ', keys %attrs), ")\n";
#  print "  Preis: $article{Preis}€\n";
#  print "  Gewicht: $article{Gewicht}kg\n";
#  $Preis += $article{Preis};
#}

#print STDERR scalar @articles, " Produkte verarbeitet im Gesamtwert von $Preis€\n";
