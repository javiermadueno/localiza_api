<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 13/06/2016
 * Time: 9:39
 */

namespace LocalizaWS\Exception;


class InvalidParameter extends \Exception
{
    function __construct($mensaje)
    {
        parent::__construct($mensaje, 3, null);
    }

} 