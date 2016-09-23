<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 09/06/2016
 * Time: 13:08
 */

namespace LocalizaWS\Repository;


use Doctrine\DBAL\Connection;

abstract class AbstractRepository
{
    /**
     * @var Connection
     */
    protected $connection;

    /**
     * @param Connection $connection
     */
    public function __construct(Connection $connection)
    {
        $this->connection = $connection;
    }

    /**
     * @return Connection
     */
    protected function getConnection()
    {
        return $this->connection;
    }
} 