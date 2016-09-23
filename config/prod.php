<?php

use Silex\Provider\MonologServiceProvider;

// configure your app for the production environment
$app['root.path'] = __DIR__ .'/../';
$app['twig.path'] = array(__DIR__.'/../templates');
$app['twig.options'] = array('cache' => __DIR__.'/../var/cache/twig');

$app['debug'] = false;
