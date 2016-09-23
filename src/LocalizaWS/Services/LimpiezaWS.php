<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 10/06/2016
 * Time: 14:20
 */

namespace LocalizaWS\Services;


class LimpiezaWS implements LimpiezaWSInterface
{

    const METHOD_STRING       = 'C_STRING';
    const METHOD_DNI          = 'C_DNI';
    const METHOD_STRING_LARGE = 'C_STRING_LARGE';
    const METHOD_TELEPHONE    = 'C_TELEPHONE';

    /**
     * @var \SoapClient
     */
    private $cliente;

    /**
     * @var string
     */
    private $username;

    /**
     * @var string
     */
    private $password;

    /**
     * @param $url
     * @param $username
     * @param $password
     */
    function __construct($url, $username, $password)
    {
        $this->cliente  = new \SoapClient($url);
        $this->username = $username;
        $this->password = $password;
    }

    /**
     * @param $method
     * @param $cadena
     *
     * @return mixed
     */
    private function call($method, $cadena)
    {
        $response = $this
            ->cliente
            ->__soapCall($method, [
                'usuario'  => $this->username,
                'password' => $this->password,
                'cadena'   => $cadena
            ]);

        return $response;
    }

    /**
     * @param $response
     * @param $metodo
     *
     * @return mixed
     * @throws \Exception
     */
    private function checkResponse($response, $metodo)
    {
        if (!is_array($response) || empty($response)) {
            throw new \Exception('Respuesta Vacia. Metodo: ' . $metodo, 4);
        }
        /** @var \StdClass $item */
        $item = $response[0];

        if ($item->resultado !== '1') {
            throw new \Exception('Fallo en el webservice de normalizacion. Metodo: ' . $metodo, 4);
        }

        return $item->cadena;
    }


    /**
     * @param $cadena
     *
     * @return mixed
     * @throws \Exception
     */
    public function limpiaCadena($cadena)
    {
        if (empty($cadena)) {
            return $cadena;
        }

        $response = $this->call(self::METHOD_STRING, $cadena);

        return $this->checkResponse($response, __METHOD__);
    }

    /**
     * @param $numero
     *
     * @return mixed
     */
    public function limpiaNumeroVia($numero)
    {
        return $numero;
    }

    /**
     * @param $telefono
     *
     * @return mixed
     * @throws \Exception
     */
    public function limpiaTelefono($telefono)
    {
        if (empty($telefono)) {
            return $telefono;
        }

        $response = $this->call(self::METHOD_TELEPHONE, $telefono);

        return $this->checkResponse($response, __METHOD__);
    }

    /**
     * @param $dni
     *
     * @return mixed
     * @throws \Exception
     */
    public function limpiaDNI($dni)
    {
        if (empty($dni)) {
            return $dni;
        }

        $response = $this->call(self::METHOD_DNI, $dni);

        return $this->checkResponse($response, __METHOD__);
    }

    /**
     * @param $cadena
     *
     * @return mixed
     * @throws \Exception
     */
    public function limpiaCadenaLarga($cadena)
    {
        if (empty($cadena)) {
            return $cadena;
        }

        $response = $this->call(self::METHOD_STRING_LARGE, $cadena);

        return $this->checkResponse($response, __METHOD__);

    }

}