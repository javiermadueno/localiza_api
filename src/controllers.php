<?php


use LocalizaWS\Services\LimpiezaWSInterface;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\HttpKernelInterface;
use Symfony\Component\Security\Core\Encoder\MessageDigestPasswordEncoder;
use Zend\Soap\Server;

//Request::setTrustedProxies(array('127.0.0.1'));


$app->get('/', function () use ($app) {
    return $app->redirect('/admin/analytics');
})->bind('homepage');

$app->match('/soap', function (Request $request) use ($app) {

    /** @var SoapServer $server */
    $server = $app['soap_server'];

    if ($request->query->has('wsdl')) {
        $subRequest = Request::create('/soap/autodiscover', 'GET', $request->query->all());
        return $app->handle($subRequest, HttpKernelInterface::SUB_REQUEST);
    }
	
	$app['logger']->info('METODO CONTROLADOR: '. $request->getRealMethod());
	$app['logger']->info('CONTENIDO REQUEST CONTROLADOR: '. $request->getContent());
	$app['logger']->info('CONTENT-TYPE REQUEST CONTROLADOR: '. $request->headers->get('Content-Type'));

    ob_start();
    $server->handle();
    $data = ob_get_clean();
    ob_end_clean();
	
	$app['logger']->info('DATA: '. $data);

    //Con esta sentencia nos aseguramos de evitar cabeceras duplicadas;
    header_remove('Content-Type');

    $headers = headers_list();


    $response = new Response($data);
    $response->headers->set('Content-Type', 'text/xml; charset=UTF-8');


    return $response;

})->bind('soap');


$app->get('/soap/autodiscover', function (Request $request) use ($app) {

    /** @var  \Zend\Soap\Wsdl $wsdl */
    $wsdl = $app['soap_autodiscover'];

    if ($request->query->has('dump')) {
        $app['app.wsdl.dumper']($app['soap_wsdl'], $wsdl->toXML());
        //$wsdl->dump($app['soap_wsdl']);
    }

    $response = new Response();
    $response->headers->set('Content-Type', 'text/xml');
    $response->setContent($wsdl->toXML());

    return $response;

})->bind('autodiscover');


$app->get('admin/generate', function(\Silex\Application $app, Request $request){

    $pass = $request->query->get('pass');

    $result = null;
    $error = false;

    if($request->query->has('pass')) {
        if (!empty($pass)) {
            $encoder = new MessageDigestPasswordEncoder();
            $result  = $encoder->encodePassword($pass, '');
        } else {
            $error = true;
        }
    }

    return $app['twig']->render('generator/index.html.twig', [
        'result' => $result,
        'error' => $error
    ]);

})->bind('generator');


$app->get('/login', function(Request $request) use ($app) {
    return $app['twig']->render('login/login.html.twig', array(
        'error'         => $app['security.last_error']($request),
        'last_username' => $app['session']->get('_security.last_username'),
    ));
});


$app->get('/prueba_ws', function (\Silex\Application $app) {
    /** @var LimpiezaWsInterface $client */
    $client   = $app['limpieza.service'];
    $cadena   = $client->limpiaCadena('PruebáéíóúÁÉÍÓÚñÑÜç');
    $dni      = $client->limpiaDNI('0987581A');
    $telefono = $client->limpiaTelefono('+34 958785232');


    $string = array_reduce([['cadena' => $cadena], ['dni' => $dni], ['telefono' => $telefono]], function($string, $elem){
        $string .= sprintf("%s: %s <br>", array_keys($elem)[0], array_values($elem)[0] );
        return $string;
    }, '' );

    return new Response($string);

})->bind('prueba');


$app->get('/admin', function(\Silex\Application $app){
    return $app->redirect('/admin/analytics');
});

$app->get('/admin/analytics', function(\Silex\Application $app){
    return $app['twig']->render('analytics/index.html.twig');
})->bind('analytics');


$clientes = $app['controllers_factory'];
$clientes->get('/', 'clientes.controller:index')->bind('clientes');
$clientes->get('/show/{id}', 'clientes.controller:show')->bind('clientes_show');

$app->mount('/admin/clientes', $clientes);

//$usuarios = $app['controllers_factory'];
//$usuarios->get('/', 'usuarios.controller:index')->bind('usuarios');
//$app->mount('/admin/usuarios', $usuarios);

$peticion = $app['controllers_factory'];
$peticion->get('/resumen', 'peticion.controller:resumenPeticiones')->bind('peticion_resumen');
$app->mount('/admin/peticion', $peticion);










/**
 * $app->error(function (\Exception $e, Request $request, $code) use ($app) {
 * if ($app['debug']) {
 * return;
 * }
 *
 * // 404.html, or 40x.html, or 4xx.html, or error.html
 * $templates = array(
 * 'errors/'.$code.'.html.twig',
 * 'errors/'.substr($code, 0, 2).'x.html.twig',
 * 'errors/'.substr($code, 0, 1).'xx.html.twig',
 * 'errors/default.html.twig',
 * );
 *
 * return new Response($app['twig']->resolveTemplate($templates)->render(array('code' => $code)), $code);
 * });
 *
 * **/
