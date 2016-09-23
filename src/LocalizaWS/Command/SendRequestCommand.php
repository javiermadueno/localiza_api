<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 19/07/2016
 * Time: 16:17
 */

namespace LocalizaWS\Command;

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Helper\Table;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class SendRequestCommand extends Command
{


    public function configure()
    {
        $this->setName('envia:peticion')
             ->addArgument('excel', InputArgument::REQUIRED, 'Fichero excel para leer', null)
             ->setDescription('Lee un fichero CSV con los parametros de peticion');
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $fichero = $input->getArgument('excel');


        if (!$fichero) {
            throw new \Exception("No se ha encontrado el fichero");
        }

        $csv = fopen($fichero, 'r');

        if ( $csv === false) {
            throw new \Exception("No se ha podido abrir el fichero");
        }

        $requests = [];

        while ($row = fgetcsv($csv, null, ';')) {
            $requests[] = [
                'request_id'    => $row[0],
                'username'      => $row[1],
                'password'      => $row[2],
                'person_id'     => $row[11],
                'name'          => $row[4],
                'name_type'     => $row[3],
                'lastname1'     => $row[5],
                'lastname2'     => $row[6],
                'dob'           => $row[24],
                'state'         => $row[23],
                'city'          => $row[21],
                'zip'           => $row[20],
                'street'        => $row[12] . ' ' . $row[13],
                'street_number' => $row[14],
                'phone'         => $row[10]


            ];
        }

        array_shift($requests);


        $output->writeln('Numero de filas leidas: '. count($requests));

        $table1 = new Table($output);
        $table1->setHeaders(array_keys(reset($requests)));
        $table1->setRows($requests);
        $table1->render();

        $client = new \SoapClient('https://apiwebservice.com/soap?wsdl');

        $results = [];

        foreach ($requests as $request) {
            $result = $client->__soapCall('localiza', [
                'LocalizaRequest' => $request
            ]);

            $result = $this->parseResponse($request, $result);

            $results = array_merge($results, $result);
        }

       $this->createCSV($fichero, $results);
    }

    private function createCSV($fichero, $data)
    {
        $ficheroEntrada = new \SplFileInfo($fichero);

        $ficheroSalida = str_replace('.'.$ficheroEntrada->getExtension(), '_salida.csv', $fichero );
        $r = fopen($ficheroSalida, 'w');

        if(count($data) > 0) {
            fputcsv($r, array_keys($data[0]), ';');
        }

        foreach ($data as $row) {
            fputcsv($r, array_values($row), ';');
        }

    }



    private function parseResponse($request, $response)
    {
        $results = [];

        unset($request['username']);
        unset($request['password']);

        $response  = json_decode(json_encode($response), true);

        foreach ($response['sources'] as $source) {
            $row = array_merge($response, $source);
            unset($row['sources']);
            $row = array_merge($request, $row);
            $results[] = $row;
        }

        return $results;

    }


}