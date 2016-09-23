<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 10/06/2016
 * Time: 11:22
 */

namespace LocalizaWS\Security\Encoder;


interface EncoderInterface
{
    /**
     * @param string $password
     *
     * @return string
     */
    public function encode($password);

    /**
     * @param string $password
     * @param string $hash
     *
     * @return bool
     */
    public function verify($password, $hash);

} 