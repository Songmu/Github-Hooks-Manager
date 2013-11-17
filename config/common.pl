use Config::PL;
my %conf = config_do 'private.pl';
+{
    dsn => ['dbi:SQLite:dbname=development.db','','', {sqlite_unicode => 1}],
    %conf,
};
