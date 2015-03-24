package Text::CSS::Readjustment;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

sub new {
    my $class = shift;
    my $args = ref $_[0] ? $_[0] : +{@_};

    my $default = {
        'output_html' => 'result.html',
        'output_css'  => 'result.css',
        'indent' => '    ',
        'html' => [],
        'css' => [],
    };

    bless { %default , %$args } , $class;
}

sub set_indent{
    my ($self,$indent_str) = @_;
    $self->{'indent'} = $indent_str;
}

sub set_output_html{
    my ($self,$name) = @_;
    $self->{'output_html'} = $name;
}

sub set_output_css{
    my ($self,$name) = @_;
    $self->{'output_css'} = $name;
}

sub add_html{
    my ($self,$html) = @_;
    $self->{'html'} ||= [];
    push @{$self->{'html'}} , $html;
}

sub clear_html{
    my ($self) = @_;
    $self->{'html'} = [];
}

sub add_css{
    my ($self,$css) = @_;
    $self->{'css'} ||= [];
    push @{$self->{'css'}} , $css;
}

sub clear_css{
    my ($self,$css) = @_;
    $self->{'css'} = [];
}

sub merge_css{
    my ($self , $html , $css) = @_;

    $html ||= $self->{html};
    $css ||= $self->{css};

    $self->_merge_css(
        $self->_read_file($self->{'html'}),
        $self->_read_file($self->{'css'})
    );
}

sub merge_css_from_dir{
    my ($self,$html_d,$css_d) = @_;
    if($css_d){
        $self->_merge_css(
            $self->_read_file($html_d),
            $self->_read_file($css_d));
    }else{
        $self->_merge_css($self->_read_file($html_d));
    }
}

sub merge_css_from_string{
    my ($self,$html_string, $css_string) = @_;
    $self->_merge_css($html_string,$css_string);
}

sub separate_string{
    my ($self,$string) = @_;
    $self->_separate_html($string);
}

sub separate_html{
    my ($self , $html) = @_;
    $html ||= $self->{html};
    $self->_separate_html(
        $self->_read_file($html)
    );
}

sub _separate_html{
    my ($self,$html) = @_;

    my $css = {
        'id' => {},
        'class' => {},
        'other' => {},
    };

    # 適当なIDの通し番号
    my $id_number = 1;
    my $sequential_id = 'id_';

    # 適当なClassの通し番号
    my $class_number = 1;
    my $sequential_class = 'class_';

    my $tree = HTML::TreeBuilder::XPath->new();

    $tree->parse($html);

    # 各要素からCSS要素を取得する。
    my @elements = $tree->findnodes('//*');

    # Style以外のタグを定義する。
    my %other_style = (
        width  => 'width',
        height => 'height',
        size  => 'size',
        bgcolor  => 'background-color',
        text  => 'color',
    );
    
    for(@elements){
        my $style;
        my $styles;
        if ($_->attr('style')){
            $style = $_->attr('style');
            $_->attr('style',undef);
            for(split ';',$style){
                my $style_name = (split ':', $_)[0];
                my $style_value = (split ':', $_)[1];
                $styles->{$style_name} = 
                    $style_value;
            }
        }elsif(
            sub{
                for my $attr(keys %other_style){
                    if ($_->attr($attr)){
                        my $style_name = $other_style{$attr};
                        my $style_value = $_->attr($attr);
                        $styles->{$style_name} =
                            $style_value;
                        $_->attr($attr,undef);
                            return 1;
                        }
                    }
                    return 0;
                }->()){
        }else{
            next;
        }

        # id がある場合idにひもづける
        if($_->attr('id')){
            my $id = $_->attr('id');
            $css->{'id'}->{$id} = $styles;
            # classがある場合、classにひもづける
#         }elsif($_->attr('class')){
            # 同一クラス名でも、Style要素が違う場合がある。(未実装)
#             my $class = $_->attr('class');
#             print Dumper $css->{'class'};
#             $css->{'class'}->{$class} = $styles;
            # classもidもない場合、その他に入力
        }else{
            # classを適当に作成して要素に入力する。
            my $class = 
                $sequential_class 
                . $class_number;
            $css->{'class'}->{$class} = $styles;
            $_->attr('class',$class);
            $class_number ++;
        }
    }

    # class内で重複する要素があると思われるので適当に重複要素をまとめる。
    # 重複するクラス名はハッシュで保持して、HTML出力時に置換する
    my $replace_class = {};
    if((ref $css->{'class'}) eq 'HASH'){
        @elements = keys %{$css->{'class'}};
        for(my $i = 0; $i < $#elements + 1 ; $i++){
            my $element = $elements[$i];
            my $value = Dumper($css->{'class'}{$element});
            for(my $j = $i + 1 ; $j < $#elements + 1 ; $j++){
                my $compare_element = $elements[$j];
                my $compare_value = Dumper($css->{'class'}{$compare_element});
                if($value eq $compare_value){
                    delete $css->{'class'}{$compare_element};
                    $replace_class->{$compare_element} = 
                        $element;
                }
            }
        }
    }

    #その他に入力されたものでclass、idと合致するものにひもづける

    # css output
    # $cssのparse
    my $output_css;
    while(my ($id , $elements) = each(%{$css->{id}})){
        my $this_element = 
            '#' . $id . "{\n";
        $this_element .= $self->_indent_css($elements);
        $this_element .= "}\n\n";
        $output_css .= $this_element;
    }

    while(my ($class , $elements) = each(%{$css->{class}})){
        my $this_element = 
            '.' . $class . "{\n";
        $this_element .= $self->_indent_css($elements);
        $this_element .= "}\n\n";
        $output_css .= $this_element;
    }
    
    # output id elements
    # output class elements
    my $css_tag = '';
    if($output_css){
        my $file_name = $self->{'output_css'};
        croak('set legal name') unless $file_name;

        my $dir = $FindBin::RealBin;
        my @dir = split '/' ,$file_name;
        for(0..$#dir-1){
            $dir .= '/' . $dir[$_];
            mkdir $dir;
        }

        open my $fh , ">" , $FindBin::RealBin . '/' . $file_name or die;
        print $fh $output_css;
        $css_tag =
            '<link rel="stylesheet" href="'
            . $file_name . '" type="text/css" />',
    }
    

    # html output
    $html = $self->_indent_html($tree ,$replace_class , $css_tag);

    {
        my $file_name = $self->{'output_html'};
        # create directory
        my $dir = $FindBin::RealBin;
        my @dir = split '/' ,$file_name;
        for(0..$#dir-1){
            $dir .= '/' . $dir[$_];
            mkdir $dir;
        }

        croak('set legal name') unless $file_name;

        open my $fh , ">" , $FindBin::RealBin . '/' . $file_name or die;
        print $fh $html;
    }
}

sub _merge_css{
    my ($self,$html,$css) = @_;

    my $tree = HTML::TreeBuilder::XPath->new();
    $tree->parse($html);
    
    # HTMLからcss読み込み部分を取得して、ファイルを読み込む
    for($tree->findnodes('//head/link')){
        my $css_dir =  
            $FindBin::RealBin . '/html/' . $_->attr('href');
        open my $fh , '<' , $css_dir 
            or croak ("Can't open such css file!:" . $css_dir);
        $css .= do { local $/; <$fh> };
    }
    
    croak ("this html not has some styles") unless $css;

    # $cssを要素に分離する

    # // コメントを取り除く
    $css =~ s/\/\/.*?\n|\/\/.*?\r//g;

    # 改行コードを取り除く
    $css =~ s/\n|\r//g;
    $css =~ s/\/\*.*?\*\///g;

    # 各要素に分割する。
    my @elements = split '}' , $css;

    for(@elements){
        my ($selector,$style) = split '{' , $_;

        my $xpath = $self->_parse_selector($selector);
        my @inner_elements = $tree->findnodes($xpath);
        for(@inner_elements){
            $_->attr('style',$style);
        }
    }

    my $file_name = $self->{'output_html'};
    croak('set file name') unless $file_name;

    open my $fh , ">" , $FindBin::RealBin . '/' . $file_name or die;

    $html = $self->_indent_html($tree);

    print $fh $html;
}

sub _read_file{
    my ($self,$files) = @_;
    if(ref $files){
        croak('no file exist') if $#{$files} eq -1;
    }else{
        $files = [$files];
    }
    my $lines;
    for(@{$files}){
        $_ = $FindBin::RealBin . '/' . $_;
        open my $fh , $_
            or croak("can't open file:" . $_);
        $lines .= do { local $/; <$fh> };
    }
    croak('no lines exist') unless $lines;
    return $lines;
}

sub _parse_selector{
    my ($self,$selector) = @_;

    $selector = '//' . $selector;
    $selector =~ s/\t|\s//g;

    # #i -> [@id='i']
    # .c -> [@class='c']

    $selector =~ s/#(.*?)(?=>|\*|\+|$)/[\@id='$1']/g;
    $selector =~ s/\.(.*?)(?=>|\*|\+|$)/[\@class='$1']/g;

    # 子ノード
    $selector =~ s/>/\/child::/g;
    # 子孫ノード
    $selector =~ s/\*/\/descendant\//g;
    # 隣接ノード
    $selector =~ s/\+/\/following-sibling\//g;
    $selector =~ s/\/\[/\/\*\[/g;
    $selector =~ s/^\[/\*\[/g;

    return $selector;
}

sub _indent_html{
    my ($self,$tree,$replace_hash,$css_tag) = @_;

    my $return_html;
    {
        no warnings;
        use HTML::Entities;
        package HTML::Entities;
        sub encode_entities{return $_[1];}

        my $html = $tree->as_HTML;

        $html =~ s/\</\n\</g;
        $html =~ s/\>/\>\n/g;
        $html =~ s/\s*\n\s*\n\s*/\n/g;

        #$html =~ s/.*(\<head\>).*/$1\n$css_tag/g;
        $html =~ s/(\<head\>)/$1\n$css_tag/g;

        while(my ($key,$value) = each(%$replace_hash)){
            $html =~ s/"$key"/"$value"/g;
        }
        my $indent_count = 0;
            for(split "\n",$html){
                next unless $_;
                if(/\/\>|\<\//){
                    $indent_count--;
            }
            $return_html .= $self->{indent} x $indent_count . $_ . "\n";
            if(/\<[^\/]/){
                unless(/\<br|\<input/){
                    $indent_count++;
                }
            }
        }
        no HTML::Entities;
    }
    return $return_html;
}

sub _indent_css{
    my ($self,$elements) = @_;
    my $this_elements;
    while(my ($element , $value) = each(%{$elements})){
        $this_elements .= 
            $self->{'indent'} . $element 
            . ' : ' . $value . ";\n";
    }
    return $this_elements;
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::CSS::Readjustment - It's new $module

=head1 SYNOPSIS

    use Text::CSS::Readjustment;

=head1 DESCRIPTION

Text::CSS::Readjustment is ...

=head1 METHODS

=head2 merge html and css

    my $r = Text::CSS::Readjustment->new()
    $r->set_output_html("exapmle.html");
    $r->merge_css_from_dir($html_file_dir, $css_file_dir);
    # output merged html with css

=head2 separate html,css files from mixed html and styles

    my $r = Text::CSS::Readjustment->new()
    $r->set_output_html("exapmle.html");
    $r->set_output_html("exapmle.css");
    $r->separate_html($html_file_dir);
    # output separated html,css

=head2 separate html,css files from mixed string

    my $r = Text::CSS::Readjustment->new(
        'output_html' => 'example.html',
        'output_css'  => 'example.css',
        'indent' => '\t',
    );
    $r->separate_string($html_string);
    # output separated html,css

=head1 LICENSE

Copyright (C) Sato shinihiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Sato shinihiro E<lt>s2otsa59@gmail.comE<gt>

=cut

