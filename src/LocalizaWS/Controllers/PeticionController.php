<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 07/07/2016
 * Time: 11:43
 */

namespace LocalizaWS\Controllers;


use LocalizaWS\Repository\PeticionRepository;
use Symfony\Component\HttpFoundation\JsonResponse;

class PeticionController
{
    /**
     * @var PeticionRepository
     */
    private $repo;

    private $twig;

    public function __construct(PeticionRepository $repo, \Twig_Environment $twig)
    {
        $this->repo = $repo;
        $this->twig = $twig;
    }


    public function index()
    {

    }

    public function resumenPeticiones()
    {
        $peticiones = $this->repo->getResumenPeticiones();

        $peticiones = array_map(function($data){
            $fecha = \DateTime::createFromFormat('Y-m-d', $data['fecha'],new \DateTimeZone('UTC'));
            //$data['fecha'] = sprintf('Date.UTC(%s, %s, %s)', $fecha->format('Y'), $fecha->format('m'), $fecha->format('d'));
            $data['fecha'] = $fecha->getTimestamp() * 1000;
            $data['total'] = (int) $data['total'];
            return array_values($data);
        }, $peticiones);



        return new JsonResponse($peticiones, 200);
    }

} 