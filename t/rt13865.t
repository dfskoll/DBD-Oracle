use strict;

use DBI;
use DBD::Oracle;

use Test::More;

use lib 't';
require 'nchar_test_lib.pl';

my $dbh = db_handle() or plan skip_all => "can't connect to database";

my %priv = map { $_ => 1 } get_privs( $dbh );

unless (    ( $priv{'CREATE TABLE'} or $priv{'CREATE ANY TABLE'} )
        and ( $priv{'DROP TABLE'} or $priv{'DROP ANY TABLE'} ) ) {
    plan skip_all => q{requires permissions 'CREATE TABLE' and 'DROP TABLE'};
}

plan tests => 3;

$dbh->do( 'DROP TABLE RT13865' );

$dbh->do( <<'END_SQL' ) or die $dbh->errstr;
CREATE TABLE RT13865(
    COL_INTEGER INTEGER,
    COL_NUMBER NUMBER,
    COL_NUMBER_37 NUMBER(37),
    COL_DECIMAL NUMBER(9,2),
    COL_FLOAT FLOAT(126)
) 
END_SQL

my $col_h = $dbh->column_info( undef, undef, 'RT13865', 'COL_INTEGER' );

is $col_h->fetchrow_hashref->{COLUMN_SIZE} => 38, 
    "INTEGER is alias for NUMBER(38)";

$col_h = $dbh->column_info( undef, undef, 'RT13865', 'COL_NUMBER_37' );
is $col_h->fetchrow_hashref->{COLUMN_SIZE} => 37, 
    "NUMBER(37)";

$col_h = $dbh->column_info( undef, undef, 'RT13865', 'COL_NUMBER' );
cmp_ok $col_h->fetchrow_hashref->{COLUMN_SIZE}, '>', 0, 
    "NUMBER";

$dbh->do( 'DROP TABLE RT13865' );

# utility functions

sub get_privs  {
    my $dbh = shift;

    my $sth = $dbh->prepare( 'SELECT PRIVILEGE from session_privs' );
    $sth->execute;

    return map { $_->[0] } @{ $sth->fetchall_arrayref };
}
