# NAME

Text::CSS::Readjustment - It's new $module

# SYNOPSIS

    use Text::CSS::Readjustment;

# DESCRIPTION

Text::CSS::Readjustment is ...

# METHODS

## merge html and css

    my $r = Text::CSS::Readjustment->new()
    $r->set_output_html("exapmle.html");
    $r->merge_css_from_dir($html_file_dir, $css_file_dir);
    # output merged html with css

## separate html,css files from mixed html and styles

    my $r = Text::CSS::Readjustment->new()
    $r->set_output_html("exapmle.html");
    $r->set_output_html("exapmle.css");
    $r->separate_html($html_file_dir);
    # output separated html,css

## separate html,css files from mixed string

    my $r = Text::CSS::Readjustment->new(
        'output_html' => 'example.html',
        'output_css'  => 'example.css',
        'indent' => '\t',
    );
    $r->separate_string($html_string);
    # output separated html,css

# LICENSE

Copyright (C) Sato shinihiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Sato shinihiro <shinichiro@wano.co.jp>
