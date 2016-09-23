<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 28/06/2016
 * Time: 12:42
 */

namespace LocalizaWS\Controllers;


use LocalizaWS\Repository\UserRespository;
use Twig_Environment as Twig;
use Silex\Controller;

class UsuariosController extends Controller
{

    protected $repo;

    protected $twig;

    public function __construct(UserRespository $repo, Twig $twig)
    {
        $this->repo = $repo;
        $this->twig = $twig;
    }


    public function index()
    {
        $usuarios = $this->repo->findAll();

        return $this->twig->render('usuarios/index.html.twig', ['usuarios' => $usuarios]);
    }

} 