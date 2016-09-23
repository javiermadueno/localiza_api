<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 10/06/2016
 * Time: 10:15
 */

namespace LocalizaWS\Model;


use LocalizaWS\Model\User\User;

class Peticion
{
    /**
     * @var int
     */
    private  $id_peticion;

    /**
     * @var string
     */
    public $request_id;

    /**
     * @var string
     */
    public $dni;

    /**
     * @var string
     */
    public $nombre;

    /**
     * @var int
     */
    public $tipo_nombre;

    /**
     * @var string
     */
    public $apellido1;

    /**
     * @var string
     */
    public $apellido2;

    /**
     * @var \DateTime
     */
    public $fecha_nacimiento;

    /**
     * @var string
     */
    public $provincia;

    /**
     * @var string
     */
    public $poblacion;

    /**
     * @var string
     */
    public $codigo_postal;

    /**
     * @var string
     */
    public $via;

    /**
     * @var string
     */
    public $numero;

    /**
     * @var string
     */
    public $telefono;

    /**
     * @var string
     */
    public $ip;


    /**
     * @var User
     */
    private $user;


    /**
     * @param $id
     *
     * @return $this
     */
    public function setId($id)
    {
        $this->id_peticion = (int) $id;

        return $this;
    }

    public function getId()
    {
        return $this->id_peticion;
    }

    /**
     * @return User
     */
    public function getUser()
    {
        return $this->user;
    }

    /**
     * @param User $user
     *
     * @return $this
     */
    public function setUser(User $user)
    {
        $this->user = $user;
        return $this;
    }

    /**
     * @return null|string
     */
    public function getFechaNacimientoSQLServer()
    {
        if($this->fecha_nacimiento instanceof \DateTime){
            return $this->fecha_nacimiento->format('Y-m-d');
        }

        return null;
    }



} 