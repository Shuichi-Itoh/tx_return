package TXR::Utils;
use strict;
use warnings;
use base qw(Exporter);
use Encode;
use DateTime;
use HTTP::Date;
use Data::Dumper;
use Scalar::Util qw(blessed);
our @datetime= qw/parse_datetime/;
our @filter = qw/trim uncomma comma/;
our @common = qw/print_out dump_out/;
our @EXPORT;
our @EXPORT_OK   = (
  @datetime,
  @filter,
  @common,
);
our %EXPORT_TAGS = (
  datetime => \@datetime,
  filter   => \@filter,
  common   => \@common,
);

#----------------------
# our @parse_datetime
#----------------------
our $tz_local;
sub tz_local {
    $tz_local ||= DateTime::TimeZone->new(name => 'local');
    return $tz_local;
}

sub parse_datetime {
    my @args = @_;
    return $args[0] if (blessed $args[0] && blessed $args[0] eq 'DateTime');
    $args[0] = join q//, @args if $args[1];
    my $epoch = str2time($args[0]);
    return DateTime->from_epoch(epoch => $epoch, time_zone => tz_local());
}
#----------------------
# our @filter
#----------------------
sub trim {
	my $text = shift;
	$text =~ s{
    ^\s*
    (.*?)
    \s*$
  }
  {$1}xms;
	return $text;
}

sub uncomma {
  my $number = shift;
  my @numbers = $number =~ /\d+/g;
  return join(q{}, @numbers);
}

sub comma {
    my $str = shift || 0;
    my $reg = '(\d+(?:\.\d+)?)';
    $str =~ s{$reg}{
        my $num = $1;
        my ($i, $j);
        if ($num =~ /^[-+]?\d\d\d\d+/g) {
            for ($i = pos($num) - 3, $j = $num =~ /^[-+]/; $i > $j; $i -= 3) {
                substr($num, $i, 0) = ',';
            }
        }
        $num;
    }eg;
    $str;
}
#----------------------
# our @common
#----------------------
sub print_out {
  my $text = shift;
  print encode_utf8($text) . "\n";
}

sub dump_out {
  my $data = shift;
  {
    no warnings 'redefine';
    package Data::Dumper;
    sub qquote { return shift; }
  }
  $Data::Dumper::Useperl = 1;
  print_out(Dumper $data);
}

1;
