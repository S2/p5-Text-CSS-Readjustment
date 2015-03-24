#!perl -w
use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;
use FindBin;
use Plack::App::Directory;
use Plack::Runner;
use WWW::Mechanize;
use Time::HiRes qw ( sleep );

use Text::CSS::Readjust;

# test Text::CSS::Readjust here

my $r = new Text::CSS::Readjust();

$r = new Text::CSS::Readjust;

# output files for test
my $new_html = '004.html';
$r->set_output_html($new_html);

opendir my $dh , $FindBin::RealBin . '/html' or die;
my @files = grep{/^004/}readdir($dh);
map{$_ = 'html/' . $_}@files;
closedir($dh);

plan(tests => $#files + 1);

# test method
while(my $file = shift @files){
    $r->merge_css_from_dir($file);

    my $html;
    {
        open my $fh, '<', $FindBin::RealBin . '/' . $new_html 
            or die "failed to open file: $!";
        $html = do { local $/; <$fh> };
    }

    ok($html =~ m/style=/s) or 
        diag(
                'html test file name:' . sub{s|$_|html/|;diag $_;$_}->($file)
                . "\ncreated:" . $html
            );
# delete created file
    system 'rm ' . $FindBin::RealBin . '/' . $new_html . ' -rf';
}

