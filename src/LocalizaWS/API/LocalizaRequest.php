<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 06/06/2016
 * Time: 12:15
 */

namespace LocalizaWS\API;


use LocalizaWS\Util\DateTimeUtil;

class LocalizaRequest
{

    /** @var  string */
    public $request_id;

    public $ip;

    /**
     * @var string
     */
    public $username;

    /**
     * @var string
     */
    public $password;

    /**
     * @var string
     */
    public $person_id;

    /**
     * @var string
     */
    public $name;

    /**
     * @var int
     */
    public $name_type;

    /**
     * @var string
     */
    public $lastname1;

    /**
     * @var string
     */
    public $lastname2;

    /**
     * @var string
     */
    public $dob;

    /**
     * @var string
     */
    public $state;

    /**
     * @var string
     */
    public $city;

    /**
     * @var string
     */
    public $zip;

    /**
     * @var string
     */
    public $street;

    /**
     * @var string
     */
    public $street_number;

    /**
     * @var string
     */
    public $phone;


    /**
     * @return null|string
     */
    public function getFechaNacimientoSQLServer()
    {
        $fechaNacimiento = DateTimeUtil::createValidDateTime($this->dob);

        if(false === $fechaNacimiento) {
            return null;
        }

        return $fechaNacimiento->format('Y-m-d');

    }



} 