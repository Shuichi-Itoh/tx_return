package TXR::Service::GeneralLedger;

use strict;
use warnings;
use base qw(TXR::Service);
use TXR::Utils qw(:common :datetime :filter);
use TXR::Service::Drawer::Text;
use utf8;
sub new {
  my $class = shift;
  my $self = bless({
    drawer => TXR::Service::Drawer::Text->new(),
  }, $class);
  return $self;
}

# 総勘定元帳ヘッダー
my @generak_ledger_en_header = (
   'date',
   'counter_title',
   'summary',
   'debit_amount',
   'credit_amount',
   'balance',
);

my @generak_ledger_ja_header = (
   '日付',
   '相手科目',
   '摘要',
   '借方金額',
   '貸方金額',
   '残高',
);

# to accessor
sub drawer {
  return shift->{drawer};
}

sub spew {
    my ($self, $slip) = @_;

    my %trial_data;

    while (my ($title, $title_data) = each (%$slip) ) {
        $self->drawer->write(sprintf("[%s]", $title));
        $self->drawer->write_as_csv(@generak_ledger_ja_header);
        my %title_data = %{$title_data};

        foreach my $month (1..12) {
            my $month_data   = $title_data{$month};
            my $debit_total  = 0;
            my $credit_total = 0;
            my $balance      = 0;

            $trial_data{$title}{$month} = {
                debit_total  => 0,
                credit_total => 0,
            };
            next unless ($month_data && ref($month_data) eq 'ARRAY');

            foreach my $rec (@{$month_data}) {
                my $date = parse_datetime($rec->{date})->strftime("%m-%d");
                my $debit_amount  = $rec->{debit_amount}  || 0;
                my $credit_amount = $rec->{credit_amount} || 0;

                $balance       = $balance + $debit_amount - $credit_amount;
                $debit_total  += $debit_amount;
                $credit_total += $credit_amount;

                #$self->drawer->write(sprintf("|%s|\t%s\t|\t%s\t|\t% 6s\t|\t% 6s\t|\t% 6s|",
                #     $date || "",
                #     $rec->{counter_title} || "ーーー",
                #     $rec->{summary} || "ーーー",
                #     comma($rec->{debit_amount})  || 0,
                #     comma($rec->{credit_amount}) || 0,
                #     comma($balance) || 0));
                $self->drawer->write_as_csv(
                    $date || "",
                    $rec->{counter_title} || "(unkown)",
                    $rec->{summary}       || "(unkown)",
                    comma($debit_amount),
                    comma($credit_amount),
                    comma($balance),
                );
            }

            # 月末処理（を’if ($month_data’の外でやるか）
            $self->drawer->write_as_csv(
                undef,
                sprintf("%s月小計", $month),
                undef,
                comma($debit_total),
                comma($credit_total),
                comma($balance)
            );
            $self->drawer->write_as_csv(
                undef,
                sprintf("%s月累計", $month),
                undef,
                undef,
                undef,
                comma($balance)
            );
            # 上書き
            $trial_data{$title}{$month} = {
                debit_total  => $debit_total,
                credit_total => $credit_total,
            };

        }# END of MONTH
        $self->drawer->write("\n");

    }# END of TITLE

    return \%trial_data;
}

1;
__END__
