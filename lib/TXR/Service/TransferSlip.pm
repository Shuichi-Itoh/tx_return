package TXR::Service::TransferSlip;
use strict;
use warnings;
use base qw(TXR::Service Class::Accessor);
use TXR::Utils qw(:datetime :filter :common );
use Text::CSV_XS;
use Path::Class;
use Encode;
use Encode::Guess qw/cp932 utf8/;

sub new {
  my $class = shift;
  my $self = bless({
      csv_xs => Text::CSV_XS->new({binary => 1}),
      enc    => undef,
  }, $class);
  return $self;
}

__PACKAGE__->mk_accessors(qw/
    csv_xs
    enc
/);

sub parse_line {
    my ($self, $line) = @_;
    $line = trim_nl($line);
    return 0 if !$line;
    #CSV変換
    unless ($self->enc) {
        my $genc = guess_encoding($line);
        $self->enc($genc->name || 'utf8');
    }
    $line = decode($self->enc, $line);
    $self->csv_xs->parse($line);
    if (!$self->csv_xs->status) {
        warn_out("ERROR INPUT 1", $self->csv_xs->error_input);
        warn_out("ERROR INPUT 2", $line);
        return 0;
    }
    my @fileds = $self->csv_xs->fields();

    my @headers = $self->transfer_slip_headers;
    my %line = map { $_ => trim(shift @fileds) } @headers;
    if (!$line{'date'}) {
        warn_out(sprintf("[%s] is no dateline", $line));
        dump_out(\%line);
        dump_out(\@fileds);
        warn "!!!!!!";
        return 0;
    }
    # そのままスルー
    if ($line{'debit_title'} eq 'nocount') {
        return 0;
    }
    warn_out(sprintf("[%s] is debit title not found!", $line))
        if !$line{'debit_title'};
    warn_out(sprintf("[%s] is credit title not found!", $line))
        if !$line{'credit_title'};

    my $this_month = parse_datetime($line{'date'})->month;
    $line{'debit_amount'} = uncomma($line{'debit_amount'});
    $line{'credit_amount'} = uncomma($line{'credit_amount'});

    return \%line;
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
    my @lines = $file->slurp;
#    shift @line; # 一行目捨てとく

    # 行ごと
    my $i = 1;
    foreach my $line (@lines) {
    # csvをハッシュ構造へ
    my $line = $self->parse_line($line);
    next unless $line;

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
          my %contents = %$line;
          # 上書き
          $contents{$counter_amount} = 0;
          $contents{'counter_title'} = $line->{$counter_title};

          my $title = $line->{$title_key};
          my $this_month = parse_datetime($line->{'date'})->month;

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
