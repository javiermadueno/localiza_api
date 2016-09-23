<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 13/06/2016
 * Time: 12:36
 */

namespace LocalizaWS\Exception;


class AccessDeniedException extends \Exception
{


    function __construct()
    {
        parent::__construct("Acceso Denegado. No tiene permiso para utilizar este metodo del WS", 1, null);
    }
}