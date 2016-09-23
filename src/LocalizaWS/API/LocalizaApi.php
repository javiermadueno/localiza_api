<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 02/06/2016
 * Time: 11:28
 */

namespace LocalizaWS\API;

use Doctrine\DBAL\DBALException;
use LocalizaWS\Exception\AccessDeniedException;
use LocalizaWS\Exception\AuthenticationException;
use LocalizaWS\Exception\DataBaseException;
use LocalizaWS\Factory\LocalizaRequestFactory;
use LocalizaWS\Model\User\User;
use LocalizaWS\Repository\PeticionRepository;
use LocalizaWS\Repository\PresalidaRepository;
use LocalizaWS\Repository\UserRespository;
use LocalizaWS\Services\NormalizaPeticion;
use Psr\Log\LoggerInterface;
use SoapFault;
use Symfony\Component\HttpFoundation\Request;

class LocalizaApi implements ApiInterface
{

    const METODO_LOCALIZA = 'LOCALIZA';

    protected $request;

    protected $userRepository;

    protected $peticionRepository;

    protected $presalidaRepository;

    protected $normalizador;

    /** @var  LoggerInterface */
    protected $log;


    function __construct(
        Request $request = null,
        UserRespository $userRespository,
        PeticionRepository $peticionRepository,
        PresalidaRepository $presalidaRepository,
        NormalizaPeticion $normalizador,
        LoggerInterface $logger
    ) {
        $this->request             = $request;
        $this->userRepository      = $userRespository;
        $this->peticionRepository  = $peticionRepository;
        $this->presalidaRepository = $presalidaRepository;
        $this->normalizador        = $normalizador;
        $this->log                 = $logger;
    }


    /**
     * Localiza con los datos que se pasan como parámetro
     *
     * @param \LocalizaWS\API\LocalizaRequest $soapRequest
     *
     * @throws SoapFault
     * @return \LocalizaWS\API\LocalizaResponse
     */
    public function localiza($soapRequest)
    {
        try {
            $soapRequest->ip = $this
                ->request
                ->getClientIp();
				
			$this->log->info('METODO: ' . $this->request->getRealMethod());

            $peticion = LocalizaRequestFactory::createFrom($soapRequest);
            $peticion = $this->normalizador->normaliza($peticion);

            $this->log->info(json_encode($soapRequest));

            $response = $this
                ->presalidaRepository
                ->creaPresalidaFrom($peticion);

            return $response;
        } catch (\Exception $e) {
            //throw $this->handleExpcetion($e);
			$this->log->critical('ALGO HA FALLADO');
            $this->log->critical($e->getMessage());
            $this->log->critical(json_encode($soapRequest));
            return $this->handleExpcetion($e);
        }

    }

    /**
     * @param $user
     * @param $pass
     *
     *
     * @return User
     *
     * @throws AuthenticationException
     * @throws DataBaseException
     * @throws AccessDeniedException
     * @throws \Exception
     */
    protected function checkUserPassword($user, $pass)
    {
        try {
            $user = $this->userRepository->findByUsername($user);

            $password = $user->getPassword();

            if (empty($password) || $pass !== $password) {
                throw new AuthenticationException();
            }

            if (!in_array(self::METODO_LOCALIZA, $user->getMetodos())) {
                throw new AccessDeniedException();
            }

            return $user;

        } catch (DBALException $e) {
            throw new DataBaseException();
        }
    }


    /**
     * @param \Exception $e
     *
     * @return SoapFault
     */
    protected function handleExpcetion(\Exception $e)
    {
        $response        = new LocalizaResponse();
        $codigoError = $e->getCode();
        $response->error = empty($codigoError) ? 1: $codigoError;

        return $response;
    }


}