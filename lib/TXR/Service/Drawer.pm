package TXR::Service::Drawer;
use strict;
use warnings;
use base qw(TXR::Service);
use TXR::Utils qw(:common);

sub write {
  my ($self, $text) = @_;
  print_out($text);
}


1;
