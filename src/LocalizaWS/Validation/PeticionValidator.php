<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 13/06/2016
 * Time: 13:03
 */

namespace LocalizaWS\Validation;

use LocalizaWS\Exception\InvalidParameter;
use Respect\Validation\Exceptions\NestedValidationException;
use Respect\Validation\Validator as v;


class PeticionValidator implements ValidatorInterface
{
    /**
     * @param $data
     *
     * @return bool
     * @throws InvalidParameter
     */
    public static function validate($data)
    {
        $validadtor =
            v::attribute('dni', v::stringType()->length(9, 9))
             ->attribute('tipo_nombre', v::optional(v::numeric()->between(1, 3)))
             ->attribute('fecha_nacimiento', v::optional(v::date('d/m/Y')))
             ->attribute('codigo_postal', v::optional(v::numeric()->length(5, 5)))
             ->attribute('telefono', v::optional(v::stringType()->length(null, 15)))
             ->attribute('numero', v::optional(v::numeric()));

        try {
            $validadtor->assert($data);
        } catch (NestedValidationException $exception) {
            throw new InvalidParameter($exception->getMessages()[0]);
        }

        return $validadtor->validate($data);
    }


} 