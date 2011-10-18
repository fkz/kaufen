#!/usr/bin/perl

use strict;
use warnings;


package Product;


sub new {
  my $class = shift;
  return bless {}, $class;
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

package Item;

sub new {
  my $class = shift;
  my $article = shift;
  my $price = shift;
  my $anzahl = shift or 1;
  my $gewicht = shift;
  my $self = [ $article, $price, $anzahl, $gewicht ];
  return bless $self, $class;
}

package Products;


my %products = ();
my $unnamedproductcount = 0;

sub insert {
  my ($class, $code) = @_;
  
  my $obj = undef;
  
  if ($code) {
    
    # check code
    if ($code !~ /^\d{8,13}$/) {
      return ("Error", "Der Code $code hat keine gültige Syntax");
    }

    my @ziffern = split //, $code;
    my $sum = 0;
    my $mul = 3 - 2*(@ziffern % 2);
    for (@ziffern) {
      $sum += $_ * $mul;
      $mul = $mul == 1 ? 3 : 1;
    }
    if ($sum % 10 != 0) {
      # error!
      return ("Error", "Der Code $code ist nicht gültig");
    }
    
    if (!($obj = $products{$code})) {
      $obj = $products{$code} = new Product;
    }
  }
  else {
    # maybe, a catching procedure can be found later. For now, just create a new object
    $obj = $products{"I$unnamedproductcount"} = {};
  }
}

1