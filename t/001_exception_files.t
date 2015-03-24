#!perl -w
use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;
use FindBin;

use Text::CSS::Readjust;

# test CSS::Readjust here

my $r = new Text::CSS::Readjust();

plan(tests => 3);
throws_ok{$r->separate_html} qr/no file exist/ , 'set no file';
$r->add_html('warestrdytfuyguhijhugyiftdr7tfyiguohip');
throws_ok{$r->separate_html} qr/can't open file/ , 'there is not file';

$r = new Text::CSS::Readjust;

$r->add_html('index.html');
lives_ok{$r->separate_html} or diag(Dumper($r->{html}));
system "rm t/result.html";
