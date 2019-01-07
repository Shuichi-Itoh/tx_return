package TXR::Service::TrialBalance;
use strict;
use warnings;
use TXR::Utils qw(:common :datetime :filter);
use YAML qw(LoadFile);
use TXR::Service::Drawer::Text;
use utf8;
# use FindBin;
# use Path::Class;
#use lib dir( $FindBin::Bin, '..', 'lib' )->stringify;

sub new {
    my $class = shift;
    my $yml = LoadFile("etc/account.yml");
    my $self = bless({
        accounts => $yml,
        drawer => TXR::Service::Drawer::Text->new(),
    }, $class);
    return $self;
}

# to accessor
sub drawer {
  return shift->{drawer};
}

sub spew {
    my ($self, $data) = @_;

    my @titles = qw/
        assets
        liabilities
        capital
        income
        expenditure
    /;
    my @headers = qw/
        科目
        １月借方 １月貸方 ２月借方 ２月貸方 ３月借方 ３月貸方
        ４月借方 ４月貸方 ５月借方 ５月貸方 ６月借方 ６月貸方
        ７月借方 ７月貸方 ８月借方 ８月貸方 ９月借方 ９月貸方
        １０月借方 １０月貸方 １１月借方 １１月貸方 １２月借方 １２月貸方
    /;
    $self->drawer->write_as_csv(@headers);
    for my $title (@titles) {
        my $accounts = $self->{accounts}->{$title};
        for my $account (@$accounts) {
            my $account_totals = $data->{$account};
            my @line = ($account);
            for my $month (1..12) {
                 my $total = $account_totals->{$month};
                 push @line,
                     $total->{debit_total},
                     $total->{credit_total};
            }
            $self->drawer->write_as_csv(@line);
        }
        $self->drawer->write("\n");
    }
}

1;
