#!/usr/bin/perl

use strict;
use warnings;

package Taxonomy;

sub category {
  my ($child, $parent) = (@_);
  push @{$child->[3]}, $parent;
  push @{$parent->[2]}, $child;
}

my %taxonomy = ();
my @taxonomy = ();

sub get {
  my ($str) = (@_);
  if ($taxonomy{$str}) { return $taxonomy{$str}; }
  $taxonomy{$str} = new Taxonomy $str;
  return $taxonomy{$str};
}

sub parent {
  my ($self) = @_;
  return @{$self->[3]}
}

sub children {
  my ($self) = @_;
  return @{$self->[2]}
}

sub term {
  return $_[0]->[1];
}

sub href {
  return 'T' . $_[0]->[0];
}

sub description {
  my @parents = $_[0]->parent;
  if (scalar @parents == 1) { return $parents[0]->term . ':' . $_[0]->[1]; }
  return $_[0]->[1];
}

sub description_link {
  my @parents = $_[0]->parent;
  my $result = '';
  if (!$_[1] && scalar @parents == 1) { 
    $result = '<a href="' . $parents[0]->href . '">' . $parents[0]->term . '</a>' . ':';
  }
  
  return $result . '<a href="' . $_[0]->href . '">' . $_[0]->[1] . '</a>';
}



sub taxonomy_from_nr {
  return $taxonomy[$_[0]];
}

sub add {
  my ($str, $item) = @_;
  my $t = get $str;
  push @$t, $item;
  return $t->[0];
}

sub new {
  my $self = bless [scalar @taxonomy, $_[1], [], []], $_[0];
  push @taxonomy, $self;
  return $self;
}

sub list {
  return (values %taxonomy);
}

sub listProducts {
  my @a = @{$_[0]};
  # liste auch Kinder
  my @result = @a[4..$#a];
  for ($_[0]->children) {
    push @result, $_->listProducts;
  }
  # entferne doppelte
 my @result2 = ();
 my $actual = 0;
 for (sort @result) {
    if ($actual != $_) {
      $actual = $_;
      push @result2, $_;
    }
 }
 return @result2;
}


sub html {
  my ($self) = @_;
  my $description = "Wortform " . term ($_[0]);
  my @items = ();

  for ($self->listProducts) {
    push @items, $_->item;
  }

  my $footer = '<div>Struktur</div><div>';
  my @parents = $self->parent;
  my @children = $self->children;
  #my @par_strs = map { $_->description_link } @parents;
  #my @ch_strs = map { $_->description_link } @children;
  #my $par = join @par_strs, ' ';

  $footer .= '<div>Eltern:' . (join ', ', map { $_->description_link (1) } @parents) . '</div>';
  $footer .= '<div>Kinder:' . (join ', ', map { $_->description_link (1) } @children) . '</div></div>';


  return Item::aggregate ($description, $footer, @items);
}



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
  
  my $self = bless {id => $id2, items => []}, $class;
  $products{$id} = $self if $id;
  push @products, $self unless $id;
  
  return $self;
}

sub setItem {
  my ($self, $item) = @_;
  push @{$self->{items}}, $item;
}

sub item {
  my ($self) = @_;
  return @{$self->{items}};
}

sub setAttribute {
  my ($self, $attribute) = @_;
  my $a = Taxonomy::add $attribute, $self;
  $self->{$a} = 1;
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
    next unless /^\d+$/;
    
    push @extra, (Taxonomy::taxonomy_from_nr $_)->description;
  }
  
  my $extra = join ' ', @extra;
  
  if ($ich{gewicht}) {
    $extra = "Gewicht: $ich{gewicht} $extra";
  }

  return "Produkt: $ich{id} ($extra)";
}

sub description_link {
  my %ich = %{$_[0]};
  my @extra = ();
  for (keys %ich) {
    next unless /^\d+$/;
    
    push @extra, (Taxonomy::taxonomy_from_nr $_)->description_link;
  }
  
  my $extra = join ' ', @extra;
  
  if ($ich{gewicht}) {
    $extra = "Gewicht: $ich{gewicht} $extra";
  }

  return "<a href='" . $_[0]->href . "'>$ich{id}</a> ($extra)";
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
  my ($class, $article, $price, $date, $place, $anzahl, $geschaeft, $gewicht) = @_;
  my $self = [ $article, $price, $date, $place, $anzahl, $gewicht, scalar @items, $geschaeft ];
  $self = bless $self, $class;
  $article->setItem ($self);
  push @items, $self;
  return $self;
}

sub geschaeft {
  return $_[0]->[7];
}

sub product {
  return $_[0]->[0];
}

sub href {
  return "item_" . $_[0]->[6];
}

sub price {
  return $_[0]->[1];
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

sub date {
  return $_[0]->[2];
}

sub description {
  my $self = shift;
  my $result = $self->[0]->description . "\n";
  if ($self->[5]) { $result .= "Gewicht: $self->[5]\n" };
  return $result;
}

sub aggregate {
  my ($description, $footer, @items) = @_;
  
  my $price = 0;
  my $table = '<table><tr><th>Datum</th><th>Geschäft</th><th>Produkt</th><th>Preis</th></tr>';
  my @pricesPerDay = ();
  my $startdate = undef;
  for (sort { $a->date <=> $b->date} @items) {
    if (!$startdate) { $startdate = $_->date; }
    my $diff = $_->date - $startdate;
    $pricesPerDay[$diff] += $_->price;
    $price += $_->price;
    $table .= '<tr><td><a href=\'' . $_->date . "'>" . $_->date . '</a></td><td>' . $_->geschaeft . '</td><td>' . $_->product->description_link . '</td>' .
     '<td>' . $_->price . '€</td></tr>';
  }
  $table .= '</table>';

    my $list = '<table><tr><th>Datum</th><th>Sonntag</th><th>Montag</th><th>Dienstag</th><th>Mittwoch</th><th>Donnerstag</th><th>Freitag</th><th>Samstag</th><th>Gesamte Woche</th></tr>';
    my $weekstart = $startdate->day_of_week;
    my $week = $startdate - $weekstart;
    my $endofline = 1;
    if ($weekstart > 0) {
      $list .= '<tr><td>' . $week . '</td>';
      $list .= "<td colspan='$weekstart'></td>";
      $endofline = 0;
    }


    my $thisweek = 0;
    for (@pricesPerDay) {
      if ($startdate->day_of_week == 0) {
	$list .= '<tr><td>' . $startdate . '</td>';
	$endofline = 0;
      }
      
      $thisweek += $_ || 0;
      my $k = $_ || '';
      ($list .= "<td><a href='$startdate'>$k</a></td>");
      
      
      if ($startdate->day_of_week == 6) {
	# Gesamtwochenpreis
	$list .= "<td>$thisweek=" . sprintf('%.2f',$thisweek/7) . "/Tag</td>";
	$thisweek = 0;
	$list .= '</tr>';
	$endofline = 1;
      }
      ++$startdate;
    }

    if (!$endofline) { $list .= '</tr>'; }
    $list .= '</table>';
  
  if (scalar @pricesPerDay <= 1) { $list = ''; }

  my $intro = "Produktanzahl: " . scalar @items . "<br />Gesamtpreis: " . $price;

  return <<HERE
<?xml version="1.0" encoding="utf8" ?>
<!DOCTYPE html PUBLIC
  "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>$description</title></head><body>
<h1>$description</h1>
<div>$intro</div>
<div>$list</div>
$table
$footer
</body>
</html> 
HERE
}

package Products;


1