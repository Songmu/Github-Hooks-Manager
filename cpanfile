requires 'Array::Diff';
requires 'Class::Accessor::Lite';
requires 'Furl';
requires 'HTML::Shakan', '1.999';
requires 'JSON::XS';
requires 'MIME::Base64';
requires 'Puncheur';
requires 'parent';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'Test::More', '0.98';
};
