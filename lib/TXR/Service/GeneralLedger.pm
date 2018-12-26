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

  while (my ($title, $title_data) = each (%$slip) ) {
      $self->drawer->write(sprintf("[%s]", $title));
      $self->drawer->write_as_csv(@generak_ledger_ja_header);
      my %title_data = %{$title_data};
      my $default_balance = get_default_balance($title);
      my $balance = $default_balance;

      my %total_default = (
        debit_amount    => 0,
        credit_amount   => 0,
      );

      my @months = qw(1 2 3 4 5 6 7 8 9 10 11 12);
      foreach my $month (@months) {

        my %total = %total_default;
        my $month_data = $title_data{$month};

        # dump_out($month_data);
        if ($month_data && ref($month_data) eq 'ARRAY') {

          foreach my $rec (@{$month_data}) {
#dump_out($rec);

            # ソートは多分いらない
            # どっちかによるのか
            $balance = $balance
                     + $rec->{debit_amount}
                     - $rec->{credit_amount}
                     ;
#print_out($balance);
            $total{$month}{debit} += $rec->{debit_amount};
            $total{$month}{credit} += $rec->{credit_amount};
            my $date = parse_datetime($rec->{date})->strftime("%m-%d");

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
                 $rec->{summary} || "(unkown)",
                 comma($rec->{debit_amount})  || 0,
                 comma($rec->{credit_amount}) || 0,
                 comma($balance) || 0
            );
          }

          # 月末処理
          $self->drawer->write_as_csv(
            undef,
            sprintf("%s月小計", $month),
            undef,
            comma($total{$month}{debit}),
            comma($total{$month}{credit}),
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
          # 改行が必要になる
        }

      }# END of MONTH
      $self->drawer->write("\n");
  }# END of TITLE

}

sub get_default_balance {
   return 0;
}


1;
__END__


sub count_view_length {
　　my $str = shift;
　　my $view_length = 0;
　　for my $char ( split q{}, $str ) {
　　　　my $sjis_char = encode( 'sjis', $char );
　　　　if ( $char =~ m/\p{InBasicLatin}/ ) {
　　　　　　$view_length += 1;
　　　　}
　　　　elsif ( $sjis_char =~ m/^$Encode::CJKConstants::RE{SJIS_KANA}$/ ) {
　　　　　　$view_length += 1;
　　　　}
　　　　else {
　　　　　　$view_length += 2;
　　　　}
　　}
　　return $view_length;
}
