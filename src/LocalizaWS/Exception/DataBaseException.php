<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 09/06/2016
 * Time: 15:17
 */

namespace LocalizaWS\Exception;


class DataBaseException extends \Exception
{

    function __construct()
    {
        parent::__construct('Error de base de datos', 2, null);
    }
}