<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 13/06/2016
 * Time: 9:28
 */

namespace LocalizaWS\Services;


use LocalizaWS\API\LocalizaRequest;

class NormalizaPeticion
{

    protected $limpiezaWS;

    function __construct(LimpiezaWSInterface $limpiezaWS)
    {
        $this->limpiezaWS = $limpiezaWS;
    }

    /**
     * @param LocalizaRequest $peticion
     *
     * @return LocalizaRequest
     */
    public function normaliza(LocalizaRequest $peticion)
    {
        $norm = $this->limpiezaWS;

        $peticion->name          = $norm->limpiaCadena($peticion->name);
        $peticion->lastname1     = $norm->limpiaCadena($peticion->lastname1);
        $peticion->lastname2     = $norm->limpiaCadena($peticion->lastname2);
        $peticion->person_id     = $norm->limpiaDNI($peticion->person_id);
        $peticion->phone         = $norm->limpiaTelefono($peticion->phone);
        $peticion->street_number = $norm->limpiaNumeroVia($peticion->street_number);
        $peticion->street        = $norm->limpiaCadena($peticion->street);

        return $peticion;
    }


} 