package Github::Hooks::Manager;
use strict;
use warnings;

our $VERSION = "0.01";

use parent 'Puncheur';

use Github::Hooks::Manager::Model::Repository;

__PACKAGE__->load_plugins('JSON');

sub repo {
    my $self = shift;

    $self->{repo} ||= Github::Hooks::Manager::Model::Repository->new(
        user       => $self->config->{user},
        password   => $self->config->{password},
        owner      => $self->config->{organization} // $self->config->{user},
        repository => $self->config->{repository},
    );
}

use Puncheur::Dispatcher::Lite;

get '/' => sub {
    my $c = shift;

    $c->render('index.tx', {
        repo => $c->repo,
    });
};

get '/:hook_id/' => sub {
    my ($c, $args) = @_;

    $c->res_json($c->repo->hook($args->{hook_id})->info);
};

get '/:hook_id/events' => sub {
    my ($c, $args) = @_;

    $c->res_json($c->repo->hook($args->{hook_id})->events);
};


post '/:hook_id/events' => sub {
    my ($c, $args) = @_;


};

get '/:hook_id/supported_events' => sub {
    my ($c, $args) = @_;

    $c->res_json($c->repo->hook($args->{hook_id})->supported_events);
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

