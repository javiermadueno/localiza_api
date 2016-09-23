<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 13/06/2016
 * Time: 15:44
 */

namespace LocalizaWS\Model\User;


use Symfony\Component\Security\Core\User\UserInterface;

/**
 * Class User
 *
 * @package LocalizaWS\Model\User
 */
class User implements UserInterface
{
    /**
     * @var
     */
    private $id;

    /**
     * @var
     */
    private $username;

    /**
     * @var
     */
    private $password;

    /**
     * @var
     */
    private $cliente;

    /**
     * @var array
     */
    private $fuentes;

    /**
     * @var array
     */
    private $metodos;

    /**
     *
     */
    public function __construct()
    {
        $this->fuentes = [];
        $this->metodos = [];
    }


    /**
     * @return array
     */
    public function getRoles()
    {
        return array('ROLE_USER');
    }

    /**
     * Returns the password used to authenticate the user.
     *
     * This should be the encoded password. On authentication, a plain-text
     * password will be salted, encoded, and then compared to this value.
     *
     * @return string The password
     */
    public function getPassword()
    {
        return $this->password;
    }

    /**
     * Returns the salt that was originally used to encode the password.
     *
     * This can return null if the password was not encoded using a salt.
     *
     * @return string|null The salt
     */
    public function getSalt()
    {
       return null;
    }

    /**
     * Returns the username used to authenticate the user.
     *
     * @return string The username
     */
    public function getUsername()
    {
        return $this->username;
    }

    /**
     * Removes sensitive data from the user.
     *
     * This is important if, at any given point, sensitive information like
     * the plain-text password is stored on this object.
     */
    public function eraseCredentials()
    {

    }

    /**
     * @return mixed
     */
    public function getId()
    {
        return $this->id;
    }

    /**
     * @param mixed $id
     *
     * @return $this
     */
    public function setId($id)
    {
        $this->id = $id;
        return $this;
    }

    /**
     * @return array
     */
    public function getFuentes()
    {
        return $this->fuentes;
    }

    /**
     * @param string $fuente
     *
     * @return $this
     */
    public function addFuente($fuente)
    {
        if(!in_array($fuente, $this->fuentes)) {
            $this->fuentes[] = $fuente;
        }

        return $this;
    }

    /**
     * @return array
     */
    public function getMetodos()
    {
        return $this->metodos;
    }

    /**
     * @param array $metodo
     *
     * @return $this
     */
    public function addMetodo($metodo)
    {
        if(!in_array($metodo, $this->metodos)) {
            $this->metodos[] = $metodo;
        }

        return $this;
    }

    /**
     * @param array $fuentes
     *
     * @return $this
     */
    public function setFuentes($fuentes)
    {
        if(!is_array($fuentes)) {
            $fuentes = array($fuentes);
        }

        $this->fuentes = $fuentes;
        return $this;
    }

    /**
     * @param array $metodos
     *
     * @return $this
     */
    public function setMetodos($metodos)
    {
        if(!is_array($metodos)) {
            $metodos = array($metodos);
        }

        $this->metodos = $metodos;

        return $this;
    }



    /**
     * @return mixed
     */
    public function getCliente()
    {
        return $this->cliente;
    }

    /**
     * @param mixed $cliente
     *
     * @return $this
     */
    public function setCliente($cliente)
    {
        $this->cliente = $cliente;
        return $this;
    }


    /**
     * @param string $username
     *
     * @return $this
     */
    public function setUsername($username)
    {
        $this->username = $username;
        return $this;
    }

    /**
     * @param string $password
     *
     * @return $this
     */
    public function setPassword($password)
    {
        $this->password = $password;

        return $this;
    }

} 