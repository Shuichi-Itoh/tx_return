package TXR::Service::GeneralLedger;
# 総勘定元帳

use strict;
use warnings;
use base qw(TXR::Service Class::Accessor);
use TXR::Utils qw(:common :datetime :filter);
use TXR::Service::Drawer::Text;
use utf8;
use YAML qw(LoadFile);
use Tie::IxHash;
use Data::Dumper;

sub new {
  my $class = shift;
  my $yml = LoadFile("etc/account.yml");
  my $self = bless({
    titles => $yml,
    drawer => TXR::Service::Drawer::Text->new(),
  }, $class);
  return $self;
}

__PACKAGE__->mk_accessors(qw(
    titles
    drawer
));

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

sub sorted_titles {
    my $self = shift;
    # 残高 = + 借方 - 貸方 or - 借方 + 貸方
    tie my %groups, 'Tie::IxHash';
    %groups = (
        assets      => '',  # 資産
        liabilities => 'reverse', # 負債
        capital     => 'reverse', # 資本
        income      => 'reverse', # 収入
        expenditure => '',  # 支出
    );

    # TITLE からみて、それがそのままか reverse かわかるようなハッシュ
    # -> ymlでかくでもいいかもね・・
    my @titles_categorys = keys %groups;
    my @sorted_titles;
    for my $category(@titles_categorys) {
        warn $category;
        my $titles = $self->titles->{$category};
        my $operation = $groups{$category};
        for my $title (@$titles) {
            if ($title eq '事業主貸') {
                push @sorted_titles, {$title => ''}
            } else {
                push @sorted_titles, {$title => $operation}
            }
        }
    }
    return @sorted_titles;
}

sub spew {
    my ($self, $slip) = @_;
    my %slip = %{$slip}; # INPUT
    my %trial_data;      # OUTPOT

    my @sorted_titles = $self->sorted_titles;

    TITLE:
    for my $title_info (@sorted_titles) {
        my ($title, $operator) = each $title_info;
        my $title_data = delete($slip{$title});
        next unless $title_data;

        $self->drawer->write(sprintf("[%s]", $title));
        $self->drawer->write_as_csv(@generak_ledger_ja_header);
        my %title_data = %{$title_data};
        my $debit_total = 0;
        my $credit_total = 0;
        my $brought_forward = 0;

        MONTH:
        foreach my $month (1..12) {
            my $month_data   = $title_data{$month};
            my $debit_subtotal  = 0;
            my $credit_subtotal = 0;
            my $balance         = $brought_forward || 0;

            $trial_data{$title}{$month} = {
                debit_total  => 0,
                credit_total => 0,
            };
            # 最終的には繰越全部出力してからの方が良さそう
            next MONTH unless ($month_data && ref($month_data) eq 'ARRAY');
            if ($brought_forward) {
                $self->drawer->write_as_csv(
                    sprintf("2018-%02d-01", $month),#年、自動でできるようにしたい
                    "",
                    "前月繰越",
                    "",
                    "",
                    comma($brought_forward),
                );
            }
            #next MONTH unless ($month_data && ref($month_data) eq 'ARRAY');

            # sort date
            my @records = map  { $_->[0] }
                          sort { $a->[1] <=> $b->[1] }
                          map  { [$_, parse_datetime($_->{date})->epoch] }
                          @{$month_data};

            foreach my $rec (@records) {
                my $date = parse_datetime($rec->{date})->strftime("%y-%m-%d");
                my $debit_amount  = $rec->{debit_amount}  || 0;
                my $credit_amount = $rec->{credit_amount} || 0;

                if ($operator eq 'reverse') {
                    $balance += ($credit_amount - $debit_amount);
                } else {
                    $balance += ($debit_amount - $credit_amount);
                }
                $debit_subtotal  += $debit_amount;
                $credit_subtotal += $credit_amount;

                $self->drawer->write_as_csv(
                    $date || "",
                    $rec->{counter_title} || "(unkown)",
                    $rec->{summary}       || "(unkown)",
                    comma($debit_amount),
                    comma($credit_amount),
                    comma($balance),
                );
            }

            $brought_forward = $balance;

            # 月末処理（を’if ($month_data’の外でやるか）
            $self->drawer->write_as_csv(
                undef,
                sprintf("%s月小計", $month),
                undef,
                comma($debit_subtotal),
                comma($credit_subtotal),
                "",# balance
            );

            $debit_total  += $debit_subtotal;
            $credit_total += $credit_subtotal;
            $self->drawer->write_as_csv(
                undef,
                sprintf("%s月累計", $month),
                undef,
                comma($debit_total),
                comma($credit_total),
                "",# balance
            );
            # 上書き
            $trial_data{$title}{$month} = {
                debit_total  => $debit_subtotal,
                credit_total => $credit_subtotal,
            };
            $self->drawer->write("");#CR
        }# END of MONTH

        $self->drawer->write("");#CR
    }# END of TITLE

    if (%{$slip}) {
        warn_out("slip data is remaind_n" . Dumper \%slip);
    }

    return \%trial_data;
}

1;
__END__
