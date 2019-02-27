package TXR::Service::TrialBalance;
use strict;
use warnings;
use base qw(TXR::Service Class::Accessor);

use TXR::Utils qw(:common :datetime :filter);
use TXR::Service::Drawer::Text;
use utf8;
use YAML qw(LoadFile);
use Tie::IxHash;

sub new {
    my ($class, $trial_data) = @_;
    my $yml = LoadFile("etc/account.yml");
    my $self = bless({
        trial_data => $trial_data,
        titles     => $yml,
        drawer     => TXR::Service::Drawer::Text->new(),
    }, $class);
    return $self;
}

__PACKAGE__->mk_accessors(qw(
    trial_data
    drawer
    titles
));

sub old_spew {
    my ($self, $data) = @_;

    tie my %groups, 'Tie::IxHash';
    %groups = (
        assets      => 'Left',  # 資産
        liabilities => 'Right', # 負債
        capital     => 'Right', # 資本
        income      => 'Right', # 収入
        expenditure => 'Left',  # 支出
    );

    my @header1 = (
        "科目",
        "１月","","２月","","３月","","４月","",
        "５月","","６月","","７月","","８月","",
        "９月","","１０月","","１１月","","１２月","",
    );

    $self->drawer->write_as_csv(@header1);

    my @headers = ("");
    map { push @headers, ("借方", "貸方") } 1..12;

    $self->drawer->write_as_csv(@headers);
    for my $group (keys %groups) {
        my $titles = $self->{titles}->{$group};
        my $side = $groups{$group};
        for my $title (@$titles) {
            my $totals = $data->{$title};
            my @line = ($title,);

            for my $month (1..12) {
                my $total = $totals->{$month};
                push @line, ( $total->{debit_total},
                              $total->{credit_total});
            }
            $self->drawer->write_as_csv(@line);
        }
        $self->drawer->write("");
    }
}

sub spew {
    my $self = shift;

    my @header1 = (
        "科目",
        "１月","","２月","","３月","",
        "４月","","５月","","６月","",
        "７月","","８月","","９月","",
        "１０月","","１１月","","１２月","",
    );
    $self->spew_by_header(1,12);

    $self->drawer->write("");
    $self->drawer->write("");
    $self->drawer->write("");
#   ２段組したい時。
#    my @header2 = (
#        "科目",
#        "７月","","８月","","９月","",
#        "１０月","","１１月","","１２月","",
#    );
#    $self->spew_by_header(7,12);
}

sub spew_by_header {
    my ($self, $start_month, $end_month) = @_;

    my @first_headers = ("月");
    my @second_headers = ("科目");
    map {
        push @first_headers,  ($_ . "月", "");
        push @second_headers, ("借方", "貸方");
    } $start_month..$end_month;

    $self->drawer->write_as_csv(@first_headers);
    $self->drawer->write_as_csv(@second_headers);

    my @groups = qw/
        assets
        liabilities
        capital
        income
        expenditure
    /;

    my %subtotal = map {
                        $_ => {
                            debit => 0,
                            credit => 0
                    } } $start_month..$end_month;

    GROUP:
    for my $group (@groups) {
        my $titles = $self->{titles}->{$group};

        # LINE
        TITLE:
        for my $title (@$titles) {
            my $totals = $self->trial_data->{$title};
            my @line = ($title,);
            MONTH:
            for my $month ($start_month..$end_month) {
                my $debit_total  = $totals->{$month}->{debit_total}  || 0;
                my $credit_total = $totals->{$month}->{credit_total} || 0;

                push @line, ( $debit_total,$credit_total);
                # 小計
                $subtotal{$month}->{debit} += $debit_total;
                $subtotal{$month}->{credit} += $credit_total;
            }
            $self->drawer->write_as_csv(@line);
        }
        $self->drawer->write("");# AS GROUP BORDER
    }
#    dump_out(\%subtotal);
    my @subtotal_lines = ("subtotal");
    for my $month ($start_month..$end_month) {
        my $subtotals = $subtotal{$month};
        push @subtotal_lines, ($subtotals->{debit}, $subtotals->{credit});
    }
    $self->drawer->write_as_csv(@subtotal_lines);

}



1;
