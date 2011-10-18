#!/usr/bin/perl


use strict;
use warnings;
use Date::Simple ('date');
use Products;

# Zeichen, die in einem Begriff auftreten dürfen
my $w = '[\wäöüÄÖÜ,!€\.%]+';

my %actual = ();

my @articles = ();
my %products = ();

my %names = ();
my @names = ();

sub get {
  my ($word) = @_;
  my $id = $names{$word};
  
  if (defined $id) { return $id; }

  push @names, ($word);
  $names{$word} = $#names;
  
  return $#names;
}

sub synonym {
  
  my ($A, $B) = @_;

  if (defined $names{$A} && defined $names{$B}) {
    warn "$A und $B wurden beide bereits benutzt; kann nicht identisch machen!";
    return;
  }
  
  (!(defined $names{$A} || defined $names{$B})) and get $A;
  my $v = $names{$A} || $names{$B};
  $names{$A} = $names{$B} = $v;
  return $v;   
}

sub kategorie {
  my ($A, $B) = @_;
  my $a = get $A;
  my $b = get $B;
  #@TODO
}

my $line = 0;
while (<>) {
  ++$line;
  if (/^\s*($w)\s*(:=|~|=)\s*($w)\s*$/) {
    if ($2 eq ':=')  {
      my $first = $1;
      my $second = $3;
      ($first !~ /^(Datum|Geschäft|Ort)$/) and warn "$first ist nicht definiert";
      if ($first eq 'Datum') {
	#parse date $second
	if ($second =~ /^(\d+)\.(\d+)\.(\d+)$/) {
	  $actual{$first} = date ($3 < 100 ? $3 + 2000 : $3, $2, $1);
	}
	else {
	  warn "$second hat kein gültiges Datumsformat";
	}
      }
      else {
	$actual{$first} = get $second;
      }
    }
    synonym $3, $1 if $2 eq '=';
    kategorie $3, $1 if $2 eq '~';
  }
  elsif (/^\s*(($w\s+)*$w)\s*$/) {
    my @words = split /\s+/;
    my %article = (
      Datum => $actual{Datum},
      Ort => $actual{Ort},
      'Geschäft' => $actual{'Geschäft'},
      Properties => {}
    );
    
    my %props = ();
    
    for (@words) {
      if (/^(\d+,?\d*)€$/) {
	$article{Preis} = $1;
	$article{Preis} =~ s/,/\./;
      }
      elsif (/^(\d+,?\d*)(kg|g)$/) {
	$article{Gewicht} = $1;
	$article{Gewicht} =~ s/,/\./;
	$2 eq 'g' and $article{Gewicht} /= 1000;
      }
      elsif (/^\d{5,13}$/) {
	$article{Code} = $_;
	#Prüfziffer berechnen:
	my @ziffern = split //;
	my $sum = 0;
	my $mul = 3 - 2*(@ziffern % 2);
	for (@ziffern) {
	  $sum += $_ * $mul;
	  $mul = $mul == 1 ? 3 : 1;
	}
	if ($sum % 10 != 0) {
	  warn "Prüfziffer falsch $_";
	}
      }
      else {
	$article{Properties}->{get $_} = 1;
      }
    }
    
    push @articles, \%article
  }
  else {
    /^\s*$/ or warn "$_ wurde nicht verarbeitet!";
  }
}

my $Preis = 0;

for (@articles) {
  my %article = %$_;
  my %attrs = %{$article{Properties}};
  print "Artikel: $article{Code} (", (join ' ', keys %attrs), ")\n";
  print "  Preis: $article{Preis}€\n";
  print "  Gewicht: $article{Gewicht}kg\n";
  $Preis += $article{Preis};
}

print STDERR scalar @articles, " Produkte verarbeitet im Gesamtwert von $Preis€\n";
