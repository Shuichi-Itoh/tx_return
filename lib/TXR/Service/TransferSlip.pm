package TXR::Service::TransferSlip;
use strict;
use warnings;
use base qw(TXR::Service);
use TXR::Utils qw(:datetime :filter :common );
use Text::CSV_XS;
use Path::Class;
use Encode;

sub csv_xs {
    my $self = shift;
    unless ($self->{_csv_xs}) {
      $self->{_csv_xs} = Text::CSV_XS->new({binary => 1});
    }
    return $self->{_csv_xs};
}

sub parse_line {
    my ($self, $line) = @_;
    #CSV変換
    $line = decode('Shift_JIS', $line);
    $self->csv_xs->parse($line);
    my @fileds = $self->csv_xs->fields();

    my @headers = $self->transfer_slip_headers;
    my %line = map { $_ => trim(shift @fileds) } @headers;
    my $this_month = parse_datetime($line{'date'})->month;
    $line{'debit_amount'} = uncomma($line{'debit_amount'});
    $line{'credit_amount'} = uncomma($line{'credit_amount'});

    return %line;
}

# 振替伝票ヘッダー
sub transfer_slip_headers {
    my $self = shift;
    my @headers = (
      'date',           # 日付
      'debit_amount',   # 借方金額
      'debit_title',    # 借方科目
      'summary',        # 摘要
      'credit_title',   # 貸方科目
      'credit_amount',  # 貸方金額
    );
    return wantarray ? @headers : \@headers;
}

sub read_csv {
    my ($self, $csv) = @_;

# 読み込み用ハッシュ
#  my %data = (
#      title => {              # 科目
#          1 => [              # 月
#　　　　　　　　　counter_title  # 相手科目
#               ****_amount    # 科目ではない金額は0にする。
#            ],
#          2 => [...],
#          3 => [...],
#      },
#  );
    my %data;

    # ファイルの読み込み
    my $file = file($csv);
    my @line = $file->slurp;
    shift @line; # 一行目捨てとく

    # 行ごと
    foreach my $line (@line) {

    # csvをハッシュ構造へ
    my %line = $self->parse_line($line);

    my @pair = (
      { credit => 'debit'  },
      { debit  => 'credit' },
    );
    for my $pair ( @pair ) {
          # 仕分け科目の特定と相手科目の処理
          my ($target, $counter) = each(%$pair);
          my $title_key      = "${target}_title";
          my $counter_title  = "${counter}_title";
          my $counter_amount = "${counter}_amount";

          # コピー
          my %contents = %line;
          # 上書き
          $contents{$counter_amount} = 0;
          $contents{'counter_title'} = $line{$counter_title};

          my $title = $line{$title_key};
          my $this_month = parse_datetime($line{'date'})->month;

          my @records;
          if ($data{$title} && ($data{$title}{$this_month})) {
              my $rec_ary = $data{$title}{$this_month};
              @records = @{$rec_ary};
          }
          push @records, \%contents;
          $data{$title}{$this_month} = \@records;

#            unless ($data{$title} && ($data{$title}{$this_month})) {
#                $data{$title}{$this_month} = [];
#            }
#            push @{ $data{$title}{$this_month} }, {%line};
    }

  }
  return \%data;
}

1;
