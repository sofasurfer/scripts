<?php
/**
 * Class to use the TinyPNG-API to shrink / compress PNG files.
 * @author Sebastian Brosch <sebastian.brosch@brosch-software.de>
 * @copyright 2014 Sebastian Brosch
 * @license http://www.gnu.org/licenses/gpl-3.0.html GNU GPL Version 3
 * @see https://tinypng.com/developers/reference
 * @version 1.0.0
 */
class TinyPNG
{
    /**
     * The curl object to communicate with the TinyPNG-API.
     * @since 1.0.0
     * @var object $curl
     */
    private $curl = null;

    /**
     * The response of the TinyPNG-API after a successfully request.
     * @since 1.0.0
     * @var array $response
     */
    private $response = array();

    /**
     * The url of the shrink / compress method of the TinyPNG-API.
     * @since 1.0.0
     * @var string $shrink_url
     */
    private $shrink_url = 'https://api.tinypng.com/shrink';

    /**
     * Constructor of the class to initialize the connection to the TinyPNG-API.
     * A key for using the TinyPNG-API can get from: https://tinypng.com/developers
     * @param string $key The TinyPNG-API key.
     * @since 1.0.0
     */
    public function __construct($key)
    {
        //Check if a curl object already exists.
        if($this->curl === null) {
            $this->curl = curl_init();

            //Set options for curl object.
            $curlOptions = array(
                CURLOPT_BINARYTRANSFER => 1,
                CURLOPT_HEADER => 1,
                CURLOPT_POST => 1,
                CURLOPT_RETURNTRANSFER => 1,
                CURLOPT_URL => $this->shrink_url,
                CURLOPT_USERAGENT => 'TinyPNG PHP v1',
                CURLOPT_USERPWD => 'api:'.$key,
            );
            curl_setopt_array($this->curl, $curlOptions);
        }
    }

    /**
     * Method to download the result of the shrink method.
     * @param string $file The file which the result will be saved.
     * @return boolean The state if the file was successfully downloaded.
     * @since 1.0.0
     */
    public function download($file)
    {
        //Check if the header of the response is available.
        if(isset($this->response['header']) === false) {
            return false;
        }

        //Extract file path of the shrink image from response header.
        foreach(explode("\r\n", $this->response['header']) as $header) {
            if(substr($header, 0, 10) === 'Location: ') {

                //Initialize a new curl object to download the file.
                $this->curl = curl_init();

                //Set options for curl object.
                $curlOptions = array(
                    CURLOPT_URL => substr($header, 10),
                    CURLOPT_RETURNTRANSFER => true,
                    CURLOPT_HEADER => 0
                );
                curl_setopt_array($this->curl, $curlOptions);

                //Get file content and save on specified file path.
                return (file_put_contents($file, curl_exec($this->curl)) !== false);
            }
        }

        //Return the state.
        return false;
    }

    /**
     * Method to get the error message if something went wrong.
     * @return string The error message if something went wrong or an empty string.
     * @since 1.0.0
     */
    public function getErrorMessage()
    {
        $content = json_decode($this->response['content'], true);

        //Check if an error message is availbale.
        if((isset($content['error']) === true) && (isset($content['message']) === true)) {
            return $content['error'].': '.$content['message'];
        }

        //Return an empty string.
        return print_r($content,true) . "*";
    }

    /**
     * Method to get the size of the input file.
     * @return integer The size of the input file in bytes.
     * @since 1.0.0
     */
    public function getInputSize()
    {
        $content = json_decode($this->response['content'], true);
        return $content['input']['size'];
    }

    /**
     * Method to get the output ratio of the shrinked file.
     * @return float The output ratio.
     * @since 1.0.0
     */
    public function getOutputRatio()
    {
        $content = json_decode($this->response['content'], true);
        return $content['output']['ratio'];
    }

    /**
     * Method to get the size of the shrinked file.
     * @return integer The size of the output file in bytes.
     * @since 1.0.0
     */
    public function getOutputSize()
    {
        $content = json_decode($this->response['content'], true);
        return $content['output']['size'];
    }

    /**
     * Get the saving percentage of the shrinked PNG file.
     * @return integer The saving percentage.
     * @since 1.0.0
     */
    public function getSavingPercentage()
    {
        return (100 - (100 * $this->getOutputRatio()));
    }

    /**
     * Get the saving size of the shrinked PNG file.
     * @return integer The saving size.
     * @since 1.0.0
     */
    public function getSavingSize()
    {
        return ($this->getInputSize() - $this->getOutputSize());
    }

    /**
     * Method to shrink a PNG file with the TinyPNG-API.
     * @param string $file The PNG file which will be shrinked by the TinyPNG-API.
     * @return boolean The state if the PNG file was successfully shrinked.
     * @since 1.0.0
     */
    public function shrink($file)
    {
        //Check if the file exists.
        if(file_exists($file) === false) {
            return false;
        }

        //Set the content of the file as additional option of curl.
        curl_setopt($this->curl, CURLOPT_POSTFIELDS, file_get_contents($file));

        //Request for shrink the file with TinyPNG-API.
        $response = curl_exec($this->curl);
        $http_code = curl_getinfo($this->curl, CURLINFO_HTTP_CODE);

        print_r($response);

        //Split header and content and save on response array.
        $this->response['header'] = substr($response, 0, curl_getinfo($this->curl, CURLINFO_HEADER_SIZE));
        $this->response['content'] = substr($response, curl_getinfo($this->curl, CURLINFO_HEADER_SIZE));

        //Check if something went wrong.
        if($http_code === 201) {
            return true;
        }

        //Return the state.
        return false;
    }
}