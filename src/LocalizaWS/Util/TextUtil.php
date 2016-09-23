<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 14/06/2016
 * Time: 11:59
 */

namespace LocalizaWS\Util;


class TextUtil
{
    public static function eliminaAcentos($text)
    {
        $text   = utf8_decode($text);
        $text   = strtolower($text);
        $text = strtr($text, utf8_decode('àáâãäçèéêëìíîïòóôõöùúûüýÿÀÁÂÃÄÇÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝ'), 'aaaaaceeeeiiiiooooouuuuyyAAAAACEEEEIIIIOOOOOUUUUY');
        $text = utf8_encode($text);
        return mb_strtoupper($text, 'UTF-8');
    }
}

