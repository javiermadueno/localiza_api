<?php
namespace LocalizaWS\Controllers;

use LocalizaWS\Repository\ClientesRepository;
use LocalizaWS\Repository\UserRespository;
use Silex\Application;
use Silex\Controller;
use Symfony\Component\Form\FormFactoryInterface;
use Symfony\Component\HttpFoundation\Request;
use Twig_Environment as Twig;

class ClientesController extends Controller
{
    /**
     * @var ClientesRepository
     */
    protected $repo;

    /**
     * @var UserRespository
     */
    protected $userRepo;

    /**
     * @var Twig
     */
    protected $twig;

    /**
     * @var FormFactoryInterface
     */
    protected $formFactory;

    /**
     * @param ClientesRepository   $repo
     * @param UserRespository      $usuarioRepository
     * @param Twig                 $twig
     * @param FormFactoryInterface $formFactory
     */
    public function __construct(ClientesRepository $repo, UserRespository $usuarioRepository, Twig $twig, FormFactoryInterface $formFactory)
    {
        $this->repo = $repo;
        $this->userRepo = $usuarioRepository;
        $this->twig = $twig;
        $this->formFactory = $formFactory;
    }

    /**
     * @return string
     */
    public function index(Request $request)
    {
        $clientes = $this->repo->findAll();
        $resumen = null;

        $formData = [
            'cliente' => null,
            'fecha_inicio' => null,
            'fecha_fin' => null,
            'facturable' => null
        ];

        $form = $this->createSearchForm($clientes, $formData);
        $form->handleRequest($request);

        if($form->isValid()) {
            $data = $form->getData();
            $resumen['data'] = $this->repo
                ->findResumenPeticionesYSalidasByClientesYFecha(
                    $data['cliente']->id_cliente,
                    $data['fecha_inicio'],
                    $data['fecha_fin'],
                    $data['facturable']);

        }

        return $this->twig->render('clientes/index.html.twig', [
            'clientes' => $clientes,
            'resumen'  => $resumen,
            'form' => $form->createView()
        ]);
    }


    private function createSearchForm($clientes, $formData)
    {
        $clientesObject = array_map(function ($cliente){ return (object) $cliente;}, $clientes);

        $form = $this->formFactory
            ->createBuilder('form', $formData, [
                'method' => Request::METHOD_GET,
                'csrf_protection' => false
            ])
            ->add('facturable', 'choice', [
                'choices' => [
                    'Todas' => 2,
                    'Facturable' => 1,
                    'No facturable' => 0
                ],
                'choices_as_values' => true,
                'placeholder' => 'Seleccione tipo de IP',
                'required' => true
            ])
            ->add('cliente', 'choice', [
                'choices' => $clientesObject,
                'choices_as_values' => true,
                'choice_label' => 'nombre',
                'choice_value' => 'id_cliente',
                'placeholder' => ' Seleccione un cliente ',
                'required' => true
            ])
            ->add('fecha_inicio', 'date', [
                'required' => false,
                'widget' => 'single_text',
                'format' => 'dd/MM/yyyy',
                'placeholder' => 'dd/mm/aaaa',
                'input' => 'datetime'
            ])
            ->add('fecha_fin', 'date', [
                'required' => false,
                'widget' => 'single_text',
                'format' => 'dd/MM/yyyy',
                'placeholder' => 'dd/mm/aaaa',
                'input' => 'datetime'
            ])
            ->getForm()
        ;

        return $form;
    }

    /**
     * @param $id
     *
     * @return string
     */
    public function show($id)
    {
        $cliente = $this->repo->findById($id);
        $resumen = $this->repo->findNumeroPeticionesYSalidasByCliente($id);
        $usuarios = $this->userRepo->findByCliente($id);

        return $this->twig->render('clientes/show.html.twig', [
            'cliente' => $cliente,
            'usuarios' => $usuarios,
            'resumen' => $resumen
        ]);
    }

} 