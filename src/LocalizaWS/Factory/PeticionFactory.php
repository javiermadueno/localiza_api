<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 10/06/2016
 * Time: 10:14
 */

namespace LocalizaWS\Factory;


use LocalizaWS\Exception\InvalidParameter;
use LocalizaWS\Model\Peticion;
use LocalizaWS\Util\DateTimeUtil;

class PeticionFactory extends CastableFactory
{

    /**
     * @param $data
     *
     * @return Peticion
     */
    public static function createFrom($data)
    {
        $peticion = new Peticion();
        self::cast($peticion, $data);
        self::creaFechaNacimiento($peticion);

        return $peticion;
    }


    protected static function creaFechaNacimiento(Peticion $peticion)
    {

        if ($peticion->fecha_nacimiento instanceof \DateTime) {
            return;
        }

        if (empty($peticion->fecha_nacimiento)) {
            return;
        }

        //Formato de fecha de la petición SOAP
        $formato         = 'd/m/Y';
        $fechaNacimiento = DateTimeUtil::createValidDateTime($peticion->fecha_nacimiento, $formato);

        if (false === $fechaNacimiento) {
            //Si ha fallado con el formato de entrada se prueba con el Formato de fecha de SQL Server
            $formato         = 'Y-m-d';
            $fechaNacimiento = DateTimeUtil::createValidDateTime($peticion->fecha_nacimiento, $formato);
        }

        if ($fechaNacimiento instanceof \DateTime) {
            $peticion->fecha_nacimiento = $fechaNacimiento;
            return;
        }

        throw new InvalidParameter(
            sprintf('El parámetro "fecha_nacimiento" con valor "%s" no es válido. Se esperaba una fecha de nacimiento con formato "dd/mm/aaaa"',
                $peticion->fecha_nacimiento
            )
        );
    }
}