<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 01/09/2016
 * Time: 17:43
 */

namespace LocalizaWS\Repository;


use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

class ClientesRepository extends AbstractRepository
{
    const TODAS_IP = 2;

    /**
     * @return \Doctrine\DBAL\Driver\Statement
     * @throws \Doctrine\DBAL\DBALException
     */
    public function findAll()
    {
        $clientes = $this
            ->getConnection()
            ->executeQuery("SELECT * FROM cliente");

        return iterator_to_array($clientes);
    }

    /**
     * @param $id
     *
     * @throws NotFoundHttpException
     * @return \Doctrine\DBAL\Driver\Statement
     */
    public function findById($id)
    {
        $cliente = $this
            ->getConnection()
            ->fetchAssoc("SELECT * FROM cliente WHERE id_cliente = ?", [$id], [\PDO::PARAM_INT]);

        if (!$cliente) {
            throw new NotFoundHttpException(sprintf("No se ha encontrado cliente con id = %s", $id));
        }

        return $cliente;
    }


    /**
     * @param $id
     *
     * @return array
     */
    public function findNumeroPeticionesYSalidasByCliente($id)
    {
        $res = $this
            ->getConnection()
            ->fetchAll(
                "SELECT c.id_cliente, c.nombre, ISNULL(l.facturable, 0) as facturable,
                    COUNT( distinct r.id_peticion) as entradas,
                    SUM (CASE WHEN p.error = 0 THEN 1 ELSE 0 END ) as salidas
                    FROM  peticion r
                    LEFT JOIN pre_salida p ON (r.id_peticion = p.id_peticion)
                    JOIN usuario u ON (r.id_usuario = u.id_usuario)
                    JOIN cliente c ON (u.id_cliente = c.id_cliente)
                    LEFT JOIN listado_ip l ON (l.IP = r.ip and c.id_cliente = l.id_cliente)
                    WHERE c.id_cliente = ?
                    GROUP BY c.id_cliente, c.nombre, l.facturable
                    ORDER BY c.id_cliente
                    ", [$id], [\PDO::PARAM_INT]);

        return $res;
    }

    /**
     * @param $id
     * @param $fechaInicio
     * @param $fechaFin
     *
     * @return array
     */
    public function findResumenPeticionesYSalidasByClientesYFecha($id, $fechaInicio, $fechaFin, $facturable)
    {

        $params = [];
        $types  = [];

        $sql = "SELECT
                  z.id_cliente,
                  z.nombre, ";

        if ($facturable != self::TODAS_IP) {
            $sql .= "z.facturable,";
        }

        $sql .= "
                  COUNT(DISTINCT z.id_peticion) as entradas,
                  SUM(
                    CASE
                      WHEN z.error = 0
                      THEN 1
                      ELSE 0
                    END) AS salidas
                FROM ({$this->createSQLPeticionesYSalidasByClientesYFechas($fechaInicio, $fechaFin)}) z
               ";

        array_push($params, $id);
        array_push($types, \PDO::PARAM_INT);

        if ($fechaInicio instanceof \DateTime) {
            array_push($params, $fechaInicio->format('Ymd'));
            array_push($types, \PDO::PARAM_STR);
        }

        if ($fechaFin instanceof \DateTime) {
            array_push($params, $fechaFin->format('Ymd'));
            array_push($types, \PDO::PARAM_STR);
        }


        if ($facturable != self::TODAS_IP) {
            $sql .= " WHERE Z.facturable = ?  ";
            array_push($params, $facturable);
            array_push($types, \PDO::PARAM_INT);
        }

        $sql .= "
                GROUP BY z.id_cliente,
                  z.nombre";

        if ($facturable != self::TODAS_IP) {
            $sql .= ", z.facturable";
        }

        $res = $this
            ->getConnection()
            ->fetchAssoc($sql, $params, $types);

        return $res;
    }


    public function createSQLPeticionesYSalidasByClientesYFechas($fechaInicio, $fechaFin)
    {
        $sql = "
            SELECT
                c.id_cliente,
                c.nombre,
                ISNULL(l.facturable, 0) AS facturable,
                r.id_peticion,
                p.id_pre_salida,
                p.error,
                r.fecha
              FROM
                peticion r
                LEFT JOIN pre_salida p
                  ON (r.id_peticion = p.id_peticion)
                JOIN usuario u
                  ON (r.id_usuario = u.id_usuario)
                JOIN cliente c
                  ON (u.id_cliente = c.id_cliente)
                LEFT JOIN listado_ip l
                  ON (
                    l.IP = r.IP
                    AND l.id_cliente = c.id_cliente
                  )
              WHERE c.id_cliente = ?
        ";

        if ($fechaInicio instanceof \DateTime) {
            $sql .= "  AND r.fecha >=  ? ";
        }

        if ($fechaFin instanceof \DateTime) {
            $sql .= "  AND r.fecha <=  ? ";
        }

        return $sql;
    }


} 