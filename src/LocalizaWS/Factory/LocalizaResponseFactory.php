<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 10/06/2016
 * Time: 9:51
 */

namespace LocalizaWS\Factory;


use LocalizaWS\API\LocalizaResponse;

class LocalizaResponseFactory extends CastableFactory
{

    /**
     * @return LocalizaResponse
     */
    public static function create()
    {
        return new LocalizaResponse();
    }

    /**
     * @param $data
     *
     * @return LocalizaResponse
     */
    public static function createFrom($data)
    {
        $response = new LocalizaResponse();
        return self::cast($response, $data);
    }

} 