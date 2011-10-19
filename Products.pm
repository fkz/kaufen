#!/usr/bin/perl

use strict;
use warnings;

# ein bestimmtes Produkt
package Product;

# benannte Produkte
my %products = ();
# unbenannte Produkte
my @products = ();

sub get {
  my $code = shift;
  if (!$code) {
    return new Product;
  }
  if ($code =~ /i(\d+)/) {
    return $products[$1];
  }
  else {
    my $result = $products{$code};
    $result = new Product $code if (!$result);
    return $result;
  }
}


sub list {
  return (@products, values %products);
}

sub id {
  my ($self) = @_;
  return $self->{id};
}

sub href {
  return $_[0]->id;
}

sub html {
  my $p = $_[0]->description;
  return <<HERE
<?xml version="1.0" encoding="utf8" ?>
<!DOCTYPE html PUBLIC
  "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Detail Produkt $p</title></head><body>
Produkt: $p
</body>
</html> 
HERE
}

sub new {
  my ($class,$id) = @_;
  my $id2 = $id || ('I' . (scalar @products));

  #check id
  if ($id) {
    if ($id !~ /^\d{8,13}$/) {
      return ("Error", "ungültiger Code");
    }
    
    my @parts = split //, $id;
    my $sum = 0;
    my $mul = 3 - 2*(@parts % 2);
    for (@parts) {
      $sum += $_ * $mul;
      $mul = $mul == 1 ? 3 : 1;
    }
    if ($sum % 10 != 0) {
      return ("Error", "Der Code '$id' ist nicht gültig!");
    }
  }
  
  my $self = bless {id => $id2}, $class;
  $products{$id} = $self if $id;
  shift @proucdts, $self unless $id;
  
  return bless {id => $id2}, $class;
}

sub setAttribute {
  my ($self, $attribute) = @_;
  $self->{$attribute} = 1;
}

sub setGewicht {
  my ($self, $gewicht) = @_;
  if ($self->{gewicht} && $self->{gewicht} != $gewicht) {
    return ("Error", "Gewicht unterschiedlich $gewicht bzw. $self->gewicht");
  }
  else {
    $self->{gewicht} = $gewicht;
  }
}

sub description {
  my %ich = %{$_[0]};
  my @extra = ();
  for (keys %ich) {
    next if $_ eq 'id';
    next if $_ eq 'gewicht';
    push @extra, $_;
  }
  
  my $extra = join ' ', @extra;
  
  if ($ich{gewicht}) {
    $extra = "Gewicht: $ich{gewicht} $extra";
  }

  return "Produkt: $ich{id} ($extra)";
}

sub htmlDescription {
  my %ich = %{$_[0]};
  return <<HERE
<div id="$ich{id}">
DESCRIPTION OF $ich{id}
</div>
HERE
}

package Item;

my @items = ();

sub new {
  my ($class, $article, $price, $date, $place, $anzahl, $gewicht) = @_;
  my $self = [ $article, $price, $date, $place, $anzahl, $gewicht, scalar @items ];
  $self = bless $self, $class;
  push @items, $self;
  return $self;
}

sub href {
  return "item_" . $_[0]->[6];
}

sub html {
  my @l = @{$_[0]};
  my $l0href = $l[0]->href;
  my $l0id = $l[0]->id;
  return <<HERE
<?xml version="1.0" encoding="utf8" ?>
<!DOCTYPE html PUBLIC
  "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Detail Item $l[6]</title></head><body>
Produkt: <a href="$l0href">$l0id</a> <br />
Preis: $l[1]€ <br />
Kaufdatum: $l[2] <br />
Einkaufsort: $l[3] <br />
Anzahl: $l[4] <br />
</body>
</html> 
HERE
}

sub list {
  return @items;
}

sub description {
  my $self = shift;
  my $result = $self->[0]->description . "\n";
  if ($self->[5]) { $result .= "Gewicht: $self->[5]\n" };
  return $result;
}

package Products;


1