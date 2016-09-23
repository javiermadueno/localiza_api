<?php

use Monolog\Formatter\LineFormatter;
use Monolog\Handler\RotatingFileHandler;
use Monolog\Logger;
use Psr\Log\LoggerInterface;
use Silex\Application;
use Silex\Provider\HttpFragmentServiceProvider;
use Silex\Provider\ServiceControllerServiceProvider;
use Silex\Provider\TwigServiceProvider;
use Silex\Provider\UrlGeneratorServiceProvider;
use Symfony\Component\Routing\Generator\UrlGeneratorInterface;
use Silex\Provider\MonologServiceProvider;


ini_set("soap.wsdl_cache_enabled", 0);

$app = new Application();


$app->register(new MonologServiceProvider(), array(
    'monolog.logfile' => __DIR__.'/../var/logs/soap_localiza.log',
));

$app->register(new UrlGeneratorServiceProvider());
$app->register(new ServiceControllerServiceProvider());
$app->register(new TwigServiceProvider());
$app->register(new HttpFragmentServiceProvider());
$app->register(new \Silex\Provider\FormServiceProvider());
$app->register(new \Silex\Provider\TranslationServiceProvider());
$app->register(new \DerAlex\Silex\YamlConfigServiceProvider(__DIR__ . '/../config/settings.yml'));


$app['ws_normalizacion.config'] = [
    'url' => 'http://213.139.1.79/desnormalizar_strings/ws_atomicas.php?wsdl',
    'username' => 'MASTER',
    'password' => '$%MeyWs01/'
];

$app->register(new \Silex\Provider\DoctrineServiceProvider(), [
    'db.options' => $app['config']['database']
]);

$app['env'] = $app->share(function(Application $app){
    return $app['debug'] ? 'dev' : 'prod';
});

$app->register(new \Silex\Provider\SessionServiceProvider());
$app->register(new Silex\Provider\SecurityServiceProvider(), array (
        'security.firewalls' => array (
            'admin' => array (
                'pattern' => '^/admin',
                //'http'    => true,
                'form' => array('login_path' => '/login', 'check_path' => '/admin/login_check'),
                'logout' => array(
                    'logout_path' => '/admin/logout',
                    'invalidate_session' => true
                ),
                'users' => $app['config']['users'] //Definidos en config/settings.yml
            ),
        )
    )
);

$app['monolog'] = $app->share($app->extend('monolog', function(Logger $monolog, $app) {

    $handler = new RotatingFileHandler($app['monolog.logfile'], 10, Logger::DEBUG);
    $formatter = new LineFormatter("[%datetime%] [%level_name%]: %message%\n", null, true, true);
    $handler->setFormatter($formatter);

    /** @var Logger $monolog */
    //$monolog->pushHandler($handler);
    $monolog->setHandlers([$handler]);

    return $monolog;
}));


/**
 * Ruta relativa del archivo wsdl
 */
$app['soap_wsdl'] = __DIR__ . "/../web/localiza.wsdl";


/**
 * @param $app
 *
 * @return \LocalizaWS\API\ApiInterface
 */
$app['api'] = $app->share(function (Application $app) {
    //$request = $app['request_stack']->getCurrentRequest();
	$request = $app['request'];
    return new LocalizaWS\API\LocalizaApi(
        $request,
        $app['user.repository'],
        $app['peticion.repository'],
        $app['presalida.repository'],
        $app['normalizador.peticion'],
        $app['logger']
    );
});

/**
 * @param $app
 *
 * @return string
 */
$app['soap_uri'] = $app->share(function (Application $app) {
    $uri = $app['url_generator']->generate('soap', [], UrlGeneratorInterface::ABSOLUTE_URL);

    return $uri;
});


/**
 * @param $app
 *
 * @return SoapServer
 */
$app['soap_server'] = function (Application $app) {

    $wsdl = $app['soap_wsdl'];

    $server = new SoapServer($wsdl, [
        'uri' => $app['soap_uri'] . '?wsdl',
        "exceptions" => true,
        'soap_version' => SOAP_1_1,
    ]);

    $server->setObject($app['api']);


    return $server;
};

/**
 * @param $app
 *
 * @return \Zend\Soap\Wsdl
 */
$app['soap_autodiscover'] = function (Application $app) {
    $autodiscover = new Zend\Soap\AutoDiscover();
    $autodiscover
        ->setClass('LocalizaWS\API\LocalizaApi')
        ->setUri($app['soap_uri'])
        ->setServiceName('LocalizaWS')
    ;

    $strategy = new \Zend\Soap\Wsdl\ComplexTypeStrategy\ArrayOfTypeComplex();
    $autodiscover->setComplexTypeStrategy($strategy);
    $wsdl = $autodiscover->generate();

    return $wsdl;
};


$app['user.repository'] = $app->share(function(Application $app) {
    return new \LocalizaWS\Repository\UserRespository($app['db']);
});

$app['peticion.repository'] = $app->share(function(Application $app) {
    return new \LocalizaWS\Repository\PeticionRepository($app['db'], $app['normalizador.peticion']);
});

$app['presalida.repository'] = $app->share(function(Application $app){
    return new \LocalizaWS\Repository\PresalidaRepository($app['db']);
});

$app['clientes.repository'] =  $app->share(function (Application $app){
   return new \LocalizaWS\Repository\ClientesRepository($app['db']);
});

$app['limpieza.service'] =  $app->share(function(Application $app){
   return new \LocalizaWS\Services\LimpiezaWS(
       $app['ws_normalizacion.config']['url'],
       $app['ws_normalizacion.config']['username'],
       $app['ws_normalizacion.config']['password']
   );
});

$app['normalizador.peticion'] = $app->share(function(Application $app){
    return new \LocalizaWS\Services\NormalizaPeticion($app['limpieza.service']);
});


$app['app.wsdl.dumper'] = $app->protect(function($filename, $content) use ($app){
    $file = fopen($filename, 'w');

    /** @var LoggerInterface $log */
    $log = $app['logger'];

    if(!$file) {
        $log->error('No se puede abrir el fichero: ' . $filename);
        return;
    }

    $log->info("Se crea el fichero {$filename} correctamente");

    fwrite($file, $content);
    fclose($file);
});

$app['clientes.controller'] = $app->share(function (\Silex\Application $app) {
    $clienteRepository = $app['clientes.repository'];
    $usuarioRespository = $app['user.repository'];
    $formFactory = $app['form.factory'];
    return new \LocalizaWS\Controllers\ClientesController($clienteRepository, $usuarioRespository, $app['twig'], $formFactory);
});


$app['usuarios.controller'] = $app->share(function (\Silex\Application $app) {
    $userRepository = $app['user.repository'];
    return new \LocalizaWS\Controllers\UsuariosController($userRepository, $app['twig']);
});

$app['peticion.controller'] = $app->share(function (\Silex\Application $app) {
    $peticionRepository = $app['peticion.repository'];
    return new \LocalizaWS\Controllers\PeticionController($peticionRepository, $app['twig']);
});




return $app;
