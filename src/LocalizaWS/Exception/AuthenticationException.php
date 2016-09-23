<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 09/06/2016
 * Time: 13:36
 */

namespace LocalizaWS\Exception;


class AuthenticationException extends \Exception
{
    function __construct()
    {
        parent::__construct('Acceso denagado. Nombre de usuario o contraseña incorrectos', 1, null);
    }
} 