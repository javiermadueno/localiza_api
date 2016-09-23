<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 14/06/2016
 * Time: 13:32
 */

namespace LocalizaWS\Factory;

use LocalizaWS\Model\User\User;


class UserFactory
{


    /**
     * @param $datos
     *
     * @return User|null
     */
    public static function createUserFromSQL($datos)
    {
        $user = null;

        foreach ($datos as $row) {
            if(!$user instanceof User) {
                $user = self::parseRow($row);
            }

            $user->addFuente($row['fuente']);
            $user->addMetodo($row['metodo']);
        }


        return $user;
    }


    public static function createArrayOfUsersFrom($datos)
    {
        $usuarios = [];

        foreach ($datos as $usuario) {
            $id_usuario = $usuario['id_usuario'];

            if(!isset($usuarios[$id_usuario])) {
                $usuarios[$id_usuario] = self::parseRow($usuario);
            }

            /** @var User $user */
            $user = $usuarios[$id_usuario];
            
            $user->addFuente($usuario['fuente']);
            $user->addMetodo($usuario['metodo']);
        }

        return $usuarios;
    }

    /**
     * @param $row
     *
     * @return User
     */
    public static function parseRow($row)
    {
        $user = new User();

        $user
            ->setId($row['id_usuario'])
            ->setUsername($row['usuario'])
            ->setPassword($row['password'])
            ->setMetodos($row['metodo'])
            ->setFuentes($row['fuente']);

        return $user;
    }

} 