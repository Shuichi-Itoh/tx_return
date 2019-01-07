package TXR::LedgerAccount;
use strict;
use warnings;
use base qw(Class::Singleton);
use Data::Properties;
use FileHandle;


1;
__END__
sub new {
    my ($class, $message_resources) = @_;
    $message_resources ||= config->message_resources;
    my $f = FileHandle->new($message_resources)
        or die "$!: $message_resources";
    my $props = Data::Properties->new;
    $props->load($f);
    $f->close;
    return bless {
        _props => $props,
    }, $class;
}


use strict;
use YAML;
use Data::Dumper;
# use utf-8;
#my ($hashref, $arrayref, $string) = Load(<<'...');
my ($hashref, $arrayref, $account_name) = Load(<<'...');
---
name: ingy       # A Mapping
age: old
weight: heavy
# I should comment that I also like pink, but don't tell anybody.
favorite colors:
  - red
  - green
  - blue
---
- Clark Evans    # A Sequence
- Oren Ben-Kiki
- Ingy dot Net
---
capital:
  - capital
assets:
  - 現金
  - 普通預金
  - 事業主貸
  - 売掛金
Liabilities:
  - 未払金
  - 事業主借
Income:
  - 売上
  - 雑収入
Expenditure:
  - 会議費
  - 旅費交通費
  - 交際費
  - 研修費
  - 地代家賃
  - 租税公課
  - 水道光熱費
  - 通信費
  - 消耗品費
  - 雑費
  - 利子割引料
  - 支払手数料
...

# Dump the Perl data structures back into YAML.
#print ">>>[ary]\n";
#print Dump($arrayref);
#print ">>>[hash]\n";
#print Dump($hashref);
print ">>>[account name]\n";
#print Dumper($account_name);
#print Dumper($account_name->{assets});

my $template = trial_balance_template($account_name);
print Dumper($template);

sub trial_balance_template {
    my $account_names = shift;
    my @template;
    for my $title (keys %$account_names) {
        my $accounts = $account_names->{$title};
        my @accounts = map{ { $_ => $title} } @$accounts;
        push @template, @accounts;
    }
    return wantarray ? @template : \@template;
}
