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
my $new_html = '003.html';
$r->set_output_html($new_html);

my @plans = (
    {
        'name' => 'standart',
        'html' => '<div class="hoge"></div>',
        'css' => '.hoge{width:100px}',
        'expect_html' => 'style\s*?=\s*?"width\s*?:\s*?100px',
    },
    {
        'name' => 'some style',
        'html' => '<div class="hoge"></div>',
        'css' => '.hoge{width:100px;height:120px;}',
        'expect_html' => 'style="width:100px;height:120px',
    },
    {
        'name' => 'some style',
        'html' => '<div class="hoge"></div>',
        'css' => '.hoge{background-color:red}',
        'expect_html' => 'style="background-color:red',
    },
);
plan(tests => $#plans + 1) ;

# test method
sub test{
    my $param = shift;
    $r->merge_css_from_string($param->{'html'},$param->{'css'});

    my $html;
    {
        open my $fh, '<', $FindBin::RealBin . '/' . $new_html 
            or die "failed to open file: $!";
        $html = do { local $/; <$fh> };
    }

    ok($html =~ m/$param->{'expect_html'}/s) or 
        diag(
                'html test name:' . $param->{'name'} . 
                "\n'expect:" . $param->{'expect_html'}
                . "\ncreated:" . $html
            );
# delete created file
    system 'rm ' . $FindBin::RealBin . '/' . $new_html . ' -rf';
}

for(@plans){
    test($_);
}
