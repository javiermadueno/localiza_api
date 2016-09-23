<?php
/**
 * Created by PhpStorm.
 * User: jmadueno
 * Date: 10/06/2016
 * Time: 9:27
 */

namespace LocalizaWS\Factory;


abstract class CastableFactory
{
    public static function cast($destination, $sourceObject)
    {
        $sourceReflection      = new \ReflectionObject($sourceObject);
        $destinationReflection = new \ReflectionObject($destination);

        $sourceProperties = $sourceReflection->getProperties();

        foreach ($sourceProperties as $sourceProperty) {
            $sourceProperty->setAccessible(true);
            $name  = $sourceProperty->getName();
            $value = $sourceProperty->getValue($sourceObject);
            if ($destinationReflection->hasProperty($name)) {
                $propDest = $destinationReflection->getProperty($name);
                $propDest->setAccessible(true);
                $propDest->setValue($destination, $value);
            } else {
                $destination->$name = $value;
            }
        }
        return $destination;
    }

} 