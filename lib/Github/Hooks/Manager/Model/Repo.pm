package Github::Hooks::Manager::Model::Repo;
use feature ':5.10';
use strict;
use warnings;
use utf8;

use Data::Dumper;
use Furl;
use JSON::XS;
use MIME::Base64 qw/encode_base64/;

use Github::Hooks::Manager::Model::Hook;

use Class::Accessor::Lite (
    new => 1,
    ro  => [qw/user password owner repository/],
);

sub _furl {
    state $f = Furl->new;
}

sub authorization {
    my $self = shift;
    $self->{authorization} ||= [Authorization => 'Basic ' . encode_base64(sprintf "%s:%s", $self->user, $self->password)];
}

sub _request_cache {
    my ($self, $key, $val) = @_;

    state $cache = {};

    if ($val) {
        $cache->{$key} = $val;
    }
    $cache->{$key};
}

sub request {
    my $self = shift;

    my %args = @_;
    push @{ $args{headers} }, @{ $self->authorization };
    my $url = $args{url};
    $args{method} = uc $args{method};

    if ($args{method} eq 'GET' && (my $cache = $self->_request_cache($url)) ) {
        push @{ $args{headers} }, ('If-None-Match',     $cache->{'etag'})          if $cache->{'etag'};
        push @{ $args{headers} }, ('If-Modified-Since', $cache->{'last-modified'}) if $cache->{'last-modified'};
    }

    my $res = _furl->request(%args);
    my $res_data;
    if ($res->code == 304) {
        $res_data = $self->_request_cache($url)->{content};
    }
    elsif ($res->is_success) {
        $res_data = decode_json $res->content;
        if ($args{method} eq 'GET' && ($res->header('etag') || $res->header('last-modified')) ) {
            $self->_request_cache($url, +{
                'etag'          => $res->header('etag')          || undef,
                'last-modified' => $res->header('last-modified') || undef,
                'content'       => $res_data,
            });
        }
    }
    else {
        die Dumper $res;
    }
    $res_data;
}

sub hook_url {
    my $self = shift;
    $self->{hook_url} ||= sprintf "https://api.github.com/repos/%s/%s/hooks", $self->owner, $self->repository
}

sub raw_hooks {
    my $self = shift;

    $self->request(method => 'GET', url => $self->hook_url);
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
