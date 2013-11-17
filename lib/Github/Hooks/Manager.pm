package Github::Hooks::Manager;
use feature ':5.10';
use strict;
use warnings;

our $VERSION = "0.01";

use parent 'Puncheur';
use Furl;
use JSON::XS;
use MIME::Base64 qw/encode_base64/;

__PACKAGE__->load_plugins('JSON');

sub user         { shift->config->{user} }
sub password     { shift->config->{password} }
sub organization { shift->config->{organization} }
sub owner        { $_[0]->organization || $_[0]->user  }
sub repository   { shift->config->{repository} }
sub hook_id      { shift->config->{hook_id}    }

sub authorization {
    my $self = shift;
    $self->{authorization} ||= [Authorization => 'Basic ' . encode_base64(sprintf "%s:%s", $self->user, $self->password)];
}

sub hook_url {
    my $self = shift;
    $self->{hook_url} ||= sprintf "https://api.github.com/repos/%s/%s/hooks/%s", $self->owner, $self->repository, $self->hook_id;
}

sub _furl {
    state $f = Furl->new;
}

sub info {
    my $self = shift;
    my $res = _furl->get($self->hook_url, $self->authorization);
    $res->is_success or die $res->content;
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

    my $res = _furl->get('https://api.github.com/hooks');
    $res->is_success or die $res->content;

    my $hooks = decode_json $res->content;
    for my $hook (@$hooks) {
        return $hook->{supported_events} if $hook->{name} eq $self->hook_name;
    }
}

use Puncheur::Dispatcher::Lite;

get '/' => sub {
    my $c = shift;
    $c->create_response(200, [], ['OK']);
};

get '/info' => sub {
    my $c = shift;

    $c->res_json($c->info);
};

get '/events' => sub {
    my $c = shift;

    $c->res_json($c->events);
};


1;
__END__

=encoding utf-8

=head1 NAME

Github::Hooks::Manager - It's new $module

=head1 SYNOPSIS

    use Github::Hooks::Manager;

=head1 DESCRIPTION

Github::Hooks::Manager is ...

=head1 LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Songmu E<lt>y.songmu@gmail.comE<gt>

=cut

