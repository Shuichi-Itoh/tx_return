package TXR::Service::Drawer;
use strict;
use warnings;
use base qw(TXR::Service);
use TXR::Utils qw(:common);

sub csv_xs {
    my $self = shift;
    unless ($self->{_csv_xs}) {
        $self->{_csv_xs} = Text::CSV_XS->new({binary => 1});
    }
    return $self->{_csv_xs};
}

sub write {
    my ($self, $text) = @_;
    print_out($text);
}

sub write_as_csv {
    my ($self, @fileds) = @_;
    @fileds = @{$fileds[0]} if (ref($fileds[0]) eq 'ARRAY');
    $self->csv_xs->combine(@fileds);
    print_out($self->csv_xs->string);
}


1;
