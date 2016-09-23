<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 16/06/2016
 * Time: 11:52
 */

namespace LocalizaWS\Repository;


use LocalizaWS\API\LocalizaRequest;
use LocalizaWS\API\LocalizaResponse;
use LocalizaWS\API\Source;


class PresalidaRepository extends AbstractRepository
{
    public function creaPresalidaFrom(LocalizaRequest $peticion)
    {
        $stmt = $this
            ->getConnection()
            ->executeQuery("EXEC spLocaliza ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?", [
                $peticion->username,
                $peticion->password,
                $peticion->request_id,
                empty($peticion->person_id) ? null : $peticion->person_id,
                $peticion->name,
                $peticion->name_type,
                $peticion->lastname1,
                $peticion->lastname2,
                $peticion->getFechaNacimientoSQLServer(),
                $peticion->state,
                $peticion->city,
                $peticion->zip,
                $peticion->street,
                $peticion->street_number,
                $peticion->phone,
                $peticion->ip
            ]);

        $presalidas = $stmt->fetchAll();

        return $this->parse($presalidas);

    }

    protected function parse($presalidas)
    {

        $response = new LocalizaResponse();

        if (empty($presalidas)) {
            return $response;
        }

        $response->response_id = $presalidas[0]['id_peticion'];
        $response->error       = $presalidas[0]['error'];
        $response->request_id  = $presalidas[0]['request_id'];

        foreach ($presalidas as $source) {
            $oPresalida = new Source();

            $oPresalida->person_validated       = $source['persona_validada'];
          //$oPresalida->direccion_validada     = $source['direccion_validada'];
            $oPresalida->phone_matching         = $source['telefono_validado'];
            $oPresalida->person_id_matching     = $source['dni_similitud'];
            $oPresalida->completename_matching  = $source['nomcom_similitud'];
            $oPresalida->name_matching          = $source['nombre_similitud'];
            $oPresalida->lastname1_matching     = $source['apellido1_similitud'];
            $oPresalida->lastname2_matching     = $source['apellido2_similitud'];
            $oPresalida->dob_matching           = $source['fecnac_similitud'];
            $oPresalida->state_matching         = $source['provincia_similitud'];
            $oPresalida->city_matching          = $source['poblacion_similitud'];
            $oPresalida->zip_matching           = $source['cp_similitud'];
            $oPresalida->street_matching        = $source['via_similitud'];
            $oPresalida->street_number_matching = $source['numero_similitud'];
            $oPresalida->source_id              = $source['fuente'];


            $response->addPresalida($oPresalida);

        }
        return $response;
    }

} 