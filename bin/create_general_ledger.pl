use strict;
use warnings;
use FindBin;
use Path::Class;
use lib dir( $FindBin::Bin, '..', 'lib' )->stringify;
use TXR::Service::TransferSlip;
use TXR::Service::GeneralLedger;
use TXR::Service::TrialBalance;
use TXR::Utils qw(:common);

=pod
use Data::Dumper;
{
  no warnings 'redefine';
  package Data::Dumper;
  sub qquote { return shift; }
}
$Data::Dumper::Useperl = 1;
=cut

my $csv_transfer_slip = shift;

my $sv_transfer_slip = TXR::Service::TransferSlip->new;
my $sv_genera_ledger = TXR::Service::GeneralLedger->new;
my $transfer_slip_data = $sv_transfer_slip->read_csv($csv_transfer_slip);
my $trial_data = $sv_genera_ledger->spew($transfer_slip_data);
# dump_out($trial_data);
my $sv_trial_blance = TXR::Service::TrialBalance->new($trial_data);
$sv_trial_blance->spew();
