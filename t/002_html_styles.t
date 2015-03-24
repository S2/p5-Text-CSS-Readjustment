#!perl -w
use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;
use FindBin;

use Text::CSS::Readjust;

# test CSS::Readjust here

my $r = new Text::CSS::Readjust();

$r = new Text::CSS::Readjust;

# output files for test
my $new_html = '002.html';
my $new_css = '002.css';
$r->set_output_html($new_html);
$r->set_output_css($new_css);

my @plans = (
    {
        'name' => 'standart',
        'html' => '<div style="width:100px;"></div>',
        'expect_html' => '<div class=".*?">.*</div>',
        'expect_css' => 'width\s*:\s*100px',
    },
    {
        'name' => 'output css style tag',
        'html' => '<div style="width:100px;"></div>',
        'expect_html' => 
            '<link rel="stylesheet" href="'
            . $new_css . '" type="text/css" />',
        'expect_css' => 'width\s*:\s*100px',
    },
    {
        'name' => 'not create duplicate element',
        'html' => '<div style="width:100px;"></div><div style="width:100px"></div>',
        'expect_html' => '<div class="class_1">.*</div>.*<div class="class_1">.*</div>',
        'expect_css' => 'width\s*:\s*100px',
        'ng_css' => 'width\s*:\s*100px.*width',
    },
    {
        'name' => 'attr=width',
        'html' => '<div width="100px"></div>',
        'expect_html' => '<div class=".*?">.*</div>',
        'expect_css' => 'width\s*:\s*100px',
    },
    {
        'name' => 'img tag like xml style "/>"',
        'html' => '<img width="100px"/>',
        'expect_html' => '<img class=".*?" />',
        'expect_css' => 'width\s*:\s*100px',
    },
    {
        'name' => 'attr=bgcolor to background-color',
        'html' => '<div bgcolor="white"></div>',
        'expect_html' => '<div class=".*?">.*</div>',
        'expect_css' => 'background-color\s*:\s*white',
    },
    {
        'name' => 'attr=text to color',
        'html' => '<div text="blue"></div>',
        'expect_html' => '<div class=".*?">.*</div>',
        'expect_css' => 'color\s*:\s*blue',
    },
);

my $ng_plan_count;
for(@plans){
    $ng_plan_count ++ if $_->{'ng_css'};
}
plan(tests => ($#plans + 1) * 2 + $ng_plan_count) ;

# test method
sub test{
    my $param = shift;
    $r->separate_string($param->{'html'});
    my ($html , $css);

    {
        open my $fh, '<', $FindBin::RealBin . '/' . $new_html 
            or die "failed to open file: $!";
        $html = do { local $/; <$fh> };
    }

    {
        open my $fh, '<', $FindBin::RealBin . '/' . $new_css 
            or die "failed to open file: $!";
        $css = do { local $/; <$fh> };
    }

    ok($html =~ m/$param->{'expect_html'}/s) or 
        diag(
                'html test name:' . $param->{'name'} . 
                "\n'expect:" . $param->{'expect_html'}
                . "\ncreated:" . $html
            );
    ok($css =~ m/$param->{'expect_css'}/s) or
        diag(
                'css test name:' . $param->{'name'} . 
                "\nexpect:" . $param->{'expect_css'}
                . "\ncreated:" . $css
            );

    if($param->{'ng_css'}){
        ok(!($css =~ m/$param->{'ng_css'}/s)) or
            diag(
                    'css test name:' . $param->{'name'} . 
                    "\nng:" . $param->{'ng_css'}
                    . "\ncreated:" . $css
                );
    }
# delete created file
    system 'rm ' . $FindBin::RealBin . '/' . $new_html . ' -rf';
    system 'rm ' . $FindBin::RealBin . '/' . $new_css . ' -rf';
}

for(@plans){
    test($_);
}
