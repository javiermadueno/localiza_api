<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 10/06/2016
 * Time: 10:12
 */

namespace LocalizaWS\Util;


class DateTimeUtil
{

    /**
     * @param \DateTime $datetime
     *
     * @return string
     */
    public static function formatSQLServerDate(\DateTime $datetime)
    {
        return $datetime->format('Y-m-d H:i:s');

    }

    /**
     * @param        $fecha
     * @param string $formato
     *
     * @return bool|\DateTime
     */
    public static function createValidDateTime($fecha, $formato = 'd/m/Y')
    {
        $dateTime = \DateTime::createFromFormat($formato, $fecha);

        $errors = \DateTime::getLastErrors();
        if (!empty($errors['warning_count']) || !empty($errors['error_count'])) {
            return false;
        }

        if($dateTime->format($formato) !== $fecha) {
            return false;
        }

        return $dateTime;
    }

} 