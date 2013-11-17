package Github::Hooks::Manager::Model::Repository;
use feature ':5.10';
use strict;
use warnings;
use utf8;

use Data::Dumper;
use JSON::XS;
use MIME::Base64 qw/encode_base64/;

use Github::Hooks::Manager::Model::Hook;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/user password owner repository/],
);

sub furl {
    state $f = Furl->new;
}

sub authorization {
    my $self = shift;
    $self->{authorization} ||= [Authorization => 'Basic ' . encode_base64(sprintf "%s:%s", $self->user, $self->password)];
}

sub request {
    my $self = shift;

    my %args = @_;
    push @{ $args{headers} }, @{ $self->authorization };
    my $res = furl->request(%args);
    $res->is_success or die Dumper $res;
    $res;
}

sub hook_url {
    my $self = shift;
    $self->{hook_url} ||= sprintf "https://api.github.com/repos/%s/%s/hooks", $self->owner, $self->repository
}

sub raw_hooks {
    my $self = shift;

    my $res = $self->request(method => 'GET', url => $self->hook_url);
    decode_json $res->content;
}

sub hooks {
    my $self = shift;
    [map {Github::Hooks::Manager::Model::Hook->new(hook_id => $_->{id}, repo => $self)} @{ $self->raw_hooks } ];
}

sub hook {
    my ($self, $hook_id) = @_;
    my ($hook) = grep { $_->hook_id == $hook_id } @{ $self->hooks };
    $hook;
}

1;
