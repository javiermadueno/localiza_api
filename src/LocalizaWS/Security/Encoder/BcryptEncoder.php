<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 10/06/2016
 * Time: 11:22
 */

namespace LocalizaWS\Security\Encoder;

class BcryptEncoder implements EncoderInterface
{

    const COST = 12;

    /**
     * @param $password
     *
     * @return string
     */
    public function encode($password)
    {
        return password_hash($password, PASSWORD_BCRYPT, ['cost' => self::COST]);
    }

    /**
     * @param $password
     * @param $hash
     *
     * @return bool
     */
    public function verify($password, $hash)
    {
        return password_verify($password, $hash);
    }


} 