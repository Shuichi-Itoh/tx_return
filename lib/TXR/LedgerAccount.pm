package TXR::LedgerAccount;
use strict;
use warnings;
use base qw(Class::Singleton);
use Data::Properties;
use FileHandle;

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
1;
