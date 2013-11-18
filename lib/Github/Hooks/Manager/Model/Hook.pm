package Github::Hooks::Manager::Model::Hook;
use strict;
use warnings;
use utf8;

use Array::Diff;
use JSON::XS;
use HTML::Shakan;
use HTML::Shakan::Field::Choice;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/repo hook_id/],
);

sub hook_url {
    my $self = shift;
    $self->{hook_url} ||= sprintf "https://api.github.com/repos/%s/%s/hooks/%s",
        $self->repo->owner, $self->repo->repository, $self->hook_id;
}

sub info {
    my $self = shift;

    $self->repo->request(method => 'GET', url => $self->hook_url);
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

    my $hooks = $self->repo->request(method => 'GET', url => 'https://api.github.com/hooks');
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

sub events_form {
    my ($self, $req) = @_;

    HTML::Shakan->new(
        fields        => [$self->_events_form_field],
        request       => $req,
        fillin_params => {events => $self->events},
    );
}

sub _events_form_field {
    my $self = shift;

    HTML::Shakan::Field::Choice->new(
        name    => 'events',
        choices => [map {($_ => $_)} @{$self->supported_events}],
        widget  => 'checkbox',
    );
}

1;
