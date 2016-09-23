<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 10/06/2016
 * Time: 9:27
 */

namespace LocalizaWS\Factory;


use LocalizaWS\API\LocalizaRequest;

class LocalizaRequestFactory extends CastableFactory
{

    /**
     * @param $data
     *
     * @return LocalizaRequest
     */
    public static function createFrom($data)
    {
        $request  = new LocalizaRequest();
        return self::cast($request, $data);
    }

    /**
     * @return LocalizaRequest
     */
    public static function create()
    {
        return new LocalizaRequest();
    }

} 