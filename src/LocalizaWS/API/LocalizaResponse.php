<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 02/06/2016
 * Time: 16:52
 */

namespace LocalizaWS\API;


class LocalizaResponse
{
    /**
     * @var int
     */
    public $response_id;


    /**
     * @var string
     */
    public $request_id;

    /**
     * @var int
     */
    public $error;

    /**
     * @var \LocalizaWS\API\Source[]
     */
    public $sources;


    public function addPresalida(Source $presalida)
    {
        if (!$presalida) {
            $this->sources = [];
        }

        $this->sources[] = $presalida;
    }

} 