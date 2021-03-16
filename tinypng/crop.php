<?php


require_once("vendor/autoload.php");





\Tinify\setKey("UYN9J1z2jsYEHbfwTQDmbs4c9roUlzEt");


$files = glob('origin/*.{jpg,png,gif,JPG}', GLOB_BRACE);
foreach($files as $file) {




    $target = str_replace("origin", "target", $file);
    $source = \Tinify\fromFile($file);
    $resized = $source->resize(array(
        "method" => "scale",
        "width" => 2500
    ));
    $resized->toFile($target);

    print  $file . ' ' . str_replace("origin", "target", $file) . "\n";
}


print "done\n";