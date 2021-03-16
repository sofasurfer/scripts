<?php


require_once('tinypng.class.php');







//Example to shrink an PNG file.
$sourcedir = '/Users/kilianbohnenblust/Downloads/putsmarie/';


$dir = new DirectoryIterator($sourcedir);

foreach ($dir as $fileinfo) {

    if( strpos($fileinfo->getFilename(), '.png') || strpos($fileinfo->getFilename(), '.jpg' ) ){

        $s = $fileinfo->getPathname();
        $t = $fileinfo->getPath() . '/shrink/' . $fileinfo->getFilename();

        echo $s . " -> " . $t . "\n";

        $tinypng = new TinyPNG('UYN9J1z2jsYEHbfwTQDmbs4c9roUlzEt');
        
        //Check if the image was successfully shrinked.
        if($tinypng->shrink($s)) {

            //Check if the file was successfully downloaded.
            if($tinypng->download($t)) {
                echo "Saving Size: ".$tinypng->getSavingSize()." Bytes\n";
                echo "Saving Percentage: ".$tinypng->getSavingPercentage()."%\n";
                echo "Input size: ".$tinypng->getInputSize()." Bytes\n";
                echo "Output size: ".$tinypng->getOutputSize()." Bytes\n";
                echo "Output ratio: ".$tinypng->getOutputRatio()."\n";
            }
        } else {
            echo "ERROR: " . $tinypng->getErrorMessage() . "\n";
        }

    }


}


return "\n";

