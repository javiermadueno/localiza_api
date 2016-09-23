<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 09/06/2016
 * Time: 17:37
 */

namespace LocalizaWS\Repository;


use Doctrine\DBAL\Connection;
use LocalizaWS\Factory\PeticionFactory;
use LocalizaWS\Model\Peticion;
use LocalizaWS\Services\NormalizaPeticion;
use LocalizaWS\Validation\PeticionValidator;


class PeticionRepository extends AbstractRepository
{

    /**
     * @var NormalizaPeticion
     */
    protected $normalizador;

    /**
     * @param Connection        $connection
     * @param NormalizaPeticion $normalizador
     */
    function __construct(Connection $connection, NormalizaPeticion $normalizador)
    {
        parent::__construct($connection);
        $this->normalizador = $normalizador;
    }

    /**
     * @param Peticion $peticion
     *
     * @return Peticion|mixed
     * @throws \Doctrine\DBAL\DBALException
     * @throws \LocalizaWS\Exception\InvalidParameter
     */
    public function save(Peticion $peticion)
    {
        $peticion = $this->normalizador->normaliza($peticion);

        $stmt = $this
            ->getConnection()
            ->executeQuery("EXEC spGeneraPeticion ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?", [
                $peticion->request_id,
                $peticion->dni,
                $peticion->nombre,
                $peticion->tipo_nombre,
                $peticion->apellido1,
                $peticion->apellido2,
                $peticion->getFechaNacimientoSQLServer(),
                $peticion->provincia,
                $peticion->poblacion,
                $peticion->codigo_postal,
                $peticion->via,
                $peticion->numero,
                $peticion->telefono,
                $peticion->ip,
                $peticion->getUser()->getId()
            ]);

        $peticion = $stmt->fetch(\PDO::FETCH_OBJ);
        $peticion = PeticionFactory::createFrom($peticion);

        return $peticion;

    }

    public function getResumenPeticiones()
    {
        $resumen = $this->getConnection()->executeQuery(
            "SELECT
              CAST(fecha as Date) as fecha, COUNT(*) as total
            FROM
              peticion
            GROUP BY
              CAST(fecha as Date)
            ORDER BY
              CAST(fecha as Date) "
        );

        return $resumen->fetchAll();
    }

} 