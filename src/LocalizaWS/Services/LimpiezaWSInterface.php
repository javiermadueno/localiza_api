<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 13/06/2016
 * Time: 9:28
 */

namespace LocalizaWS\Services;


interface LimpiezaWSInterface
{
    public function limpiaCadena($cadena);

    public function limpiaNumeroVia($numero);

    public function limpiaTelefono($telefono);

    public function limpiaDNI($dni);

    public function limpiaCadenaLarga($cadena);
} 