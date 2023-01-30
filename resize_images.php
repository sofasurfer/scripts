<?php
/**
 * Script to resize images in a folder
 * Rum from cli: php -d memory_limit=1024M -d display_errors=on  resize_images.php 
 * 
 */


$maxwidth = 1200;
$maxheight = 1200;
$quality = 80; 
$sourcePath = "./images/large/";
$destPath = "./images/small/";
$images= glob($sourcePath."*");
$start_time = microtime(true);
$counter = 0;

echo "Start: " . $destPath."\n";

foreach ($images as $filename) {
    //resize the image
    $newfilename = $destPath . basename($filename);

    if(resizeImage($filename,$newfilename,$maxwidth,$maxheight,$quality)){
        echo ".";
        $counter++;
    }else{
        echo "\n" . $filename . " not found\n";
    }
}

$end_time = microtime(true);
  
// Calculate script execution time
$execution_time = ($end_time - $start_time);

echo $counter . " files convertet execution time of script = ".$execution_time." sec";


/**
 * Resize image - preserve ratio of width and height.
 * @param string $sourceImage path to source JPEG image
 * @param string $targetImage path to final JPEG image file
 * @param int $maxWidth maximum width of final image (value 0 - width is optional)
 * @param int $maxHeight maximum height of final image (value 0 - height is optional)
 * @param int $quality quality of final image (0-100)
 * @return bool
 */
function resizeImage($sourceImage, $targetImage, $maxWidth, $maxHeight, $quality = 80)
{
    
    // Obtain image from given source file.
    if(exif_imagetype($sourceImage) == IMAGETYPE_JPEG){
        $image = @imagecreatefromjpeg($sourceImage);
    }else if(exif_imagetype($sourceImage) == IMAGETYPE_PNG){
        $image = @imagecreatefrompng($sourceImage);
    }


    if (!$image){
        return false;
    }

    // Get dimensions of source image.
    list($origWidth, $origHeight) = getimagesize($sourceImage);

    // Check if file is larger then max width or height
    if( $origWidth <=  $maxWidth || $origHeight<= $maxHeight ){
        copy($sourceImage, $targetImage);
        return true;
    }

    if ($maxWidth == 0){
        $maxWidth  = $origWidth;
    }
    if ($maxHeight == 0){
        $maxHeight = $origHeight;
    }

    // Calculate ratio of desired maximum sizes and original sizes.
    $widthRatio = $maxWidth / $origWidth;
    $heightRatio = $maxHeight / $origHeight;

    // Ratio used for calculating new image dimensions.
    $ratio = min($widthRatio, $heightRatio);

    // Calculate new image dimensions.
    $newWidth  = (int)$origWidth  * $ratio;
    $newHeight = (int)$origHeight * $ratio;

    // Create final image with new dimensions.
    $newImage = imagecreatetruecolor($newWidth, $newHeight);
    imagecopyresampled($newImage, $image, 0, 0, 0, 0, $newWidth, $newHeight, $origWidth, $origHeight);
    

    if(exif_imagetype($sourceImage) == IMAGETYPE_JPEG){
        imagejpeg($newImage, $targetImage, $quality);
    }else if(exif_imagetype($sourceImage) == IMAGETYPE_PNG){
        imagepng($newImage, $targetImage, 9);
    }

    // Free up the memory.
    imagedestroy($image);
    imagedestroy($newImage);

    return true;
}