<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 14/06/2016
 * Time: 11:21
 */

namespace LocalizaWS\Security\Authentication\Token;


use Symfony\Component\Security\Core\Authentication\Token\AbstractToken;
use Symfony\Component\Security\Guard\Token\GuardTokenInterface;

class SoapToken  extends AbstractToken implements GuardTokenInterface
{
    /**
     * Returns the user credentials.
     *
     * @return mixed The user credentials
     */
    public function getCredentials()
    {
        // TODO: Implement getCredentials() method.
    }


} 