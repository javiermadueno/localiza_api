<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 02/06/2016
 * Time: 11:19
 */

namespace LocalizaWS\User;


interface UserInterface
{

    public function getUser();

    public function getCredentials();

    public function getRoles();

} 