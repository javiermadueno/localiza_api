<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 09/06/2016
 * Time: 13:09
 */

namespace LocalizaWS\Repository;


use LocalizaWS\Factory\UserFactory;
use LocalizaWS\Model\User\User;
use Symfony\Component\Security\Core\Exception\UsernameNotFoundException;

class UserRespository extends AbstractRepository
{
    /**
     * @param $username
     *
     * @return User
     * @throws \Doctrine\DBAL\DBALException
     * @throws \Exception
     */
    public function findByUsername($username)
    {
        $stmt = $this->getConnection()->executeQuery("EXEC spGetUsuario ?", [$username]);

        if (!$user = $stmt->fetchAll()) {
            throw new UsernameNotFoundException(sprintf("No se ha encontrado el usuario '%s'", $username));
        }

        $user = UserFactory::createUserFromSQL($user);

        return $user;
    }


    /**
     * @return array
     */
    public function findAll()
    {
        $users = $this->getConnection()->fetchAll("SELECT * FROM usuario");

        return $users;
    }

    public function findByCliente($id_cliente)
    {

        $sql = "
            SELECT
              usuario.id_usuario,
              id_cliente,
              usuario,
              usuario.password,
              fuente,
              metodo
            FROM
              usuario
              LEFT JOIN usuario_fuente
                ON (
                  usuario_fuente.id_usuario = usuario.id_usuario
                )
              LEFT JOIN fuentes
                ON (
                  usuario_fuente.id_fuente = fuentes.id_fuente
                )
              LEFT JOIN usuario_metodo
                ON (
                  usuario_metodo.id_usuario = usuario.id_usuario
                )
              LEFT JOIN metodos
                ON (
                  usuario_metodo.id_metodo = metodos.id_metodo
                )
              WHERE usuario.id_cliente = ?
        ";
        $users = $this
            ->getConnection()
            ->fetchAll($sql, [$id_cliente], [\PDO::PARAM_INT]);

        return UserFactory::createArrayOfUsersFrom($users);

       return $users;
    }

} 