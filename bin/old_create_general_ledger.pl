use strict;
use warnings;
use lib qw(/Users/shuichiitoh/perl5/lib/orign);
use Utils qw(:datetime :filter :common );
use Data::Dumper;
{
    package Data::Dumper;
  sub qquote { return shift; }
}
$Data::Dumper::Useperl = 1;
use Text::CSV_XS;
use Path::Class;
use Encode;
use List::MoreUtils qw(zip);

my $csv_transfer_slip = shift;

my $file = file($csv_transfer_slip);

# 振替伝票ヘッダー
my @transfer_slip_headers = (
   'date',           # 日付
   'debit_amount',   # 借方金額
   'debit_title',    # 借方科目
   'summary',        # 摘要
   'credit_title',   # 貸方科目
   'credit_amount',  # 貸方金額
);

# 総勘定元帳ヘッダー
my @generak_ledger_header = (
   'date',
   'counter_title',
   'debit_amount',
   'credit_amount',
   'summary',
   'balance',
);

=pod
読み込み用ハッシュ
my %data = (
    title => {
        1 => [

          ],
        2 => [...],
        3 => [...],
    }

);
=cut

my %data;

my $csv_xs = Text::CSV_XS->new({binary => 1});
my $dt = DateTime->now(time_zone => 'local');

# ファイルの読み込み
my @line = $file->slurp;
shift @line; # 一行目捨てとく

# 行ごと
foreach my $line (@line) {
    #CSV変換
    $line = decode('Shift_JIS', $line);
    $csv_xs->parse($line);
    my @fileds = $csv_xs->fields();
    # csvをハッシュ構造へ
    my %line = map { $_ => trim(shift @fileds) } @transfer_slip_headers;
    my $this_month = parse_datetime($line{'date'})->month;
    $line{'debit_amount'} = uncomma($line{'debit_amount'});
    $line{'credit_amount'} = uncomma($line{'credit_amount'});

    for my $title_key (qw/debit_title credit_title/) {
          my $title = $line{$title_key};
          unless ($data{$title} && ($data{$title}{$this_month})) {
              $data{$title}{$this_month} = [];
          }
          push @{ $data{$title}{$this_month} }, {%line};
    }
}

#warn Dumper \%data;

output_data(\%data);
# 伝票出力

sub output_data {
  my $data = shift;
  :TITLE
  while (my ($title, $title_data) = each (%$data) ) {
      _print(sprintf("[%s]", $title);
      #my %title_data = $data{$title};
      my %title_data = %{$title_data};
      my $default_balance = get_default_balance($title);
      my $balance = $default_balance;
      my @months = qw(1 2 3 4 5 6 7 8 9 10 11 12);
      my $total = map { $_->{
         debit  => 0,
         credit => 0,
      }} @months;
      :MONTH
      foreach my $month (keys %title_data) {
          my $month_ary = $title_data{$month};
          :RECORD
          foreach my $rec (@month_ary) {
              # ソートは多分いらない
              $balance = $balance
                       + $rec{debit_amount}
                       - $rec{credit_amount}
                       ;
              $total->{$month}{debit} += $rec{debit_amount};
              $total->{$month}{credit} += $rec{credit_amount};
              _print(sprintf("%s,%s,%s,%s,%s,%s,"
                   $rec{date},
                   $rec{counter_tille},
                   $rec{summary},
                   $rec{debit_amount},
                   $rec{credit_amount},
                   $balance));
          };
          # 月末処理
          _print(sprintf(",Month total,,%s,%s,",
              $total->{$month}{debit},
              $total->{$month}{credit},
         ));
      }
  }
}

sub get_default_balance {
   return 0;
}
