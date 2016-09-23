<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 08/06/2016
 * Time: 16:50
 */

namespace LocalizaWS\Bridge\Silex;

use LocalizaWS\API\LocalizaApi;
use Silex\Application;
use Silex\ServiceProviderInterface;
use Symfony\Component\Routing\Generator\UrlGeneratorInterface;
use Zend\Soap\AutoDiscover;
use Zend\Soap\Server;
use Zend\Soap\Wsdl\ComplexTypeStrategy\ArrayOfTypeComplex;

class SoapServiceProvider implements ServiceProviderInterface
{
    /**
     * Registers services on the given app.
     *
     * This method should only be used to configure services and parameters.
     * It should not get services.
     *
     * @param Application $app
     */
    public function register(Application $app)
    {
        /**
         * Ruta relativa del archivo wsdl
         */
        $app['soap_wsdl'] = __DIR__."/../web/localiza.wsdl";


        /**
         * @param $app
         *
         * @return string
         */
        $app['soap_uri'] = $app->share(function (Application $app) {
            $uri =  $app['url_generator']->generate('soap', [], UrlGeneratorInterface::ABSOLUTE_URL);
            $app['monolog']->debug('SOAP_URI => ' . $uri);

            return $uri;
        });


        /**
         * @param $app
         *
         * @return \Zend\Soap\Server
         */
        $app['soap_server'] = $app->share(function (Application $app) {

            $wsdl = $app['soap_wsdl'];

            $server = new Server($wsdl, [
                'uri' => $app['soap_uri'] . '?wsdl',
            ]);

            $server->setObject($app['api']);
            $server->setReturnResponse(true);

            return $server;
        });

        /**
         * @param $app
         *
         * @return \Zend\Soap\Wsdl
         */
        $app['soap_autodiscover'] = $app->share(function (Application $app) {
            $autodiscover = new AutoDiscover();
            $autodiscover
                ->setClass(LocalizaApi::class)
                ->setUri($app['soap_uri'])
                ->setServiceName('LocalizaWS');

            $strategy = new ArrayOfTypeComplex();
            $autodiscover->setComplexTypeStrategy($strategy);
            $wsdl = $autodiscover->generate();

            return $wsdl;
        });
    }

    /**
     * Bootstraps the application.
     *
     * This method is called after all services are registered
     * and should be used for "dynamic" configuration (whenever
     * a service must be requested).
     */
    public function boot(Application $app)
    {
        // TODO: Implement boot() method.
    }


} 