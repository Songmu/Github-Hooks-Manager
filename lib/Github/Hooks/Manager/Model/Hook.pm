package Github::Hooks::Manager::Model::Hook;
use strict;
use warnings;
use utf8;

use Array::Diff;
use Scalar::Util ();
use JSON::XS;

use Class::Accessor::Lite (
    ro  => [qw/repo hook_id/],
);

sub new {
    my ($class, %args) = @_;
    my $self = +{%args};
    Scalar::Util::weaken $self->{repo};
    bless $self, $class;
}

sub hook_url {
    my $self = shift;
    $self->{hook_url} ||= sprintf "https://api.github.com/repos/%s/%s/hooks/%s",
        $self->repo->owner, $self->repo->repository, $self->hook_id;
}

sub info {
    my $self = shift;

    my $res = $self->repo->request(method => 'GET', url => $self->hook_url);
    decode_json $res->content;
}

sub hook_name {
    my $self = shift;
    $self->{hook_name} ||= $self->info->{name};
}

sub events {
    shift->info->{events};
}

sub supported_events {
    my $self = shift;

    my $res = $self->repo->furl->get('https://api.github.com/hooks');
    $res->is_success or die $res->content;

    my $hooks = decode_json $res->content;
    for my $hook (@$hooks) {
        return $hook->{supported_events} if $hook->{name} eq $self->hook_name;
    }
}

sub update_events {
    my ($self, @events) = @_;

    my $diff = Array::Diff->diff([sort @{$self->events}], [sort @events]);

    $self->add_events(@{ $diff->added });
    my $res = $self->remove_events(@{ $diff->deleted });

    $res;
}

sub add_events {
    my ($self, @events) = @_;

    my $body = encode_json {add_events => [@events]};

    $self->repo->request(
        method  => 'PATCH',
        url     => $self->hook_url,
        content => $body,
    );
}

sub remove_events {
    my ($self, @events) = @_;

    my $body = encode_json {remove_events => [@events]};

    $self->repo->request(
        method  => 'PATCH',
        url     => $self->hook_url,
        content => $body,
    );
}

1;
