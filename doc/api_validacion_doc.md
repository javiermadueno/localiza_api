#Web Service Verificacion

[TOC]

##Base de datos
###Tablas

* **usuarios**: Es la tabla donde se almacena el nombre de usuario y contraseña y a qué cliente pertenece el usuario. Si se quiere añadir un usuario solo hay que añadir un registro a esta tabla.
*  **cliente**: Almacena los clientes que pueden acceder al webservice. Esta tabla contiene dos campos (`consolida` y `transforma`) de tipo `bit` que indica si la salida es consolidada, transforma, ambas o ninguna de las dos.
*  **fuentes**: Almacena las diferentes fuentes que hay en el sistema. Contiene la clave primaria `id_fuente` y `valor` que contiene un valor potencia de 2 para hacer operaciones de bit y asi poder calcular si un usuario tiene permisos para utilizar esa fuente o no.
*  **usuario_fuente**: Almacena las fuentes permitidas para un usuario.
*  **cliente_parametro**: Almacena la tabla con los rangos de valores necesarios para transformar la salida.
*  **peticion**: Almacena todos los datos que llegan en la `petición` del webservice.
*  **pre_salida**: Almacena las presalidas para cada una de las fuentes.

###Procedimientos almacenados

* **spLocaliza**: Es el procedimiento de entrada al sistema. Recibe como parámetro todos los datos de la peticíon. Es el encargado de comprobar el login, crear una nuevo registro en la tabla `peticion`, comprobar los permisos de usuario y crear las `pre_salidas` correspondientes según los permisos que tiene el usuario.
* **spLogin**: Comprueba que existe el nombre de usuario y que la contraseña es la correcta.
* **spGeneraPeticion**: Crea un registro nuevo en la tabla `peticion`con los datos aportados.
* **spCreaPresalidas**: Este procedimiento almacenado recibe como parámetro el `id_peticion` que se ha obtenido en el procedimiento almacenado anterior. Busca todas las fuentes que hay registradas en el sistema y calcula los permisos que tiene el usuario. Por cada fuente llama al procedimiento `spInsertaPresalida` para crear un registro nuevo.
* **spGetFuentesUsuario**: Obtiene un entero que representa los permisos que tiene el usuario. Cada fuente tiene un valor que es potencia de 2, de tal manera que si un usuario tiene permiso para utilizar la F1, F2 y F5 se obtendrá un valor de 1 + 2 + 16 = 19

	| Fuente | Valor |
	|--------|-------|
	| F1     | 1     |
	| F2     | 2     |
	| F3     | 4     |
	| F4     | 8     |
	| F5     | 16    |
	| F6     | 32    |
    Con este valor y utilizando la operacion de bit `&` se puede saber si el usuario tiene permisos para la fuente. Si el valor de esta opeación es distinto de 0 es que el usuario tiene permisos para esta fuente.
* **spBuscaIdPersona**: Busca el `ID_PERSONA` en las tablas del webservice según los parametros especificados (DNI, Fecha_nacimiento, nombre_completo).
* **spInsertaPresalida**: Recibe el `id_peticion`y el valor correspondiente de la `fuente`. Busca en las tablas de datos del Webservice los datos correspondientes de la petición y la fuente especificada y crea una presalida.
* **spConsolidaPresalidas**: Agrupa los registros que hay en la tabla `pre_salida` para una petición y coge el mejor resultado para cada campo.
* **spTransformaPresalida**: Haciendo uso de la tabla `cliente_parametro` transforma el valor de las pre_salidas por los valores 1, 2 o 0 según el rango en el que se ecuentre.
* **spConsolidaYTransforma:**: Primero consolida las fuentes y despues las transforma.

##SOAP Webservice PHP
Para el servidor SOAP se ha utilizado el microframework `Silex` que utiliza los componentes de `Symfony`.

Los directorios mas importantes son:
* **config/**: Se encuentran los archivos de configuracion de la aplicacion segun este en modo `debug` o no.
* **src/**: Contiene toda la lógica de la aplicación. Modelo de datos, repositorios, Factories...
* **web/**: Es el punto de entrada de la aplicación a traves del navegador. Contiene dos ficheros principales `index.php` e `index_dev.php`. El primero es el modo producción y el segundo el modo desarrollo.
* **var/**: Contiene los logs del sistema.

Los archivos importantes son:
* **config/settings.yml** : Es un achivo Yaml que contiene los parámetros de conexión a base de datos. No se ha incluido en el repositorio para cuando se actualice en producción no se sobreescriba con los datos de desarrollo.
* **src/app.php**: Crea la aplicación de silex propiamente dicha. En este archivo se definen todas las clases necesarias en el contenedor de dependencias.
* **src/controllers.php**: En este archivo se define el código que se ejecuta según la URL.
* **src/API/LocalizaRequest.php**:Clase que el servidor SOAP utiliza para mapear el `request`
* **src/API/LocalizaResponse.php**: Clase que se utiliza para generar la respuesta del servidor SOAP.
* **src/API/LocalizaApi.php**: Contiene la lógica del método `localiza` del webservice.

###Errores
Estos son los errores que devuelve el WS:
* **1**: Error de Login. Usuario o contraseña incorrectos;
* **2**: Error de Base de datos
* **3**: Parámetro no válido
* **4**: Error de permisos. El usuario no tiene asignado ninguna fuente que se puede consultar o no tiene permiso para utilizat el método.

##Página de administración
Se ha creado una pagína de administración para poder consultar el número de peticiones realizadas por día y el número de peticiones que ha realizado un cliente en un rango de fechas determinado.
Para poder entrar a la parte de administración es necesario nombre de usuario y contraseña:

| Dato   | Valor        |
|--------|--------------|
|User    | admin        |
|Pass    | Arcoiris2015 |


La configuracion del firewall de `Silex` se realiza en el archivo `src\app.php`:

```php
$app->register(new Silex\Provider\SecurityServiceProvider(), array (
        'security.firewalls' => array (
            'admin' => array (
                'pattern' => '^/admin',
                'form' => array('login_path' => '/login', 'check_path' => '/admin/login_check'),
                'logout' => array(
                    'logout_path' => '/admin/logout',
                    'invalidate_session' => true
                ),
                'users' => $app['config']['users'] //Definidos en config/settings.yml
                    ),
                ),
            ),
        )
    )
);
```

Con esta configuración se está indicando que todas las URLs que comiencen con el patrón `/admin` necesitarán login para poder acceder.

Los usuario que pueden entrar en la sección de administración estan definidos en el archivo de configuracion `config\settings.yml` que contiene una seccion de usuarios:

```yml
users:
    admin: [ROLE_ADMIN, lOCBXsYmQttwqQiqt7phHmF3uhC9JD6E7IYiipZ9V5CmEJaaKmnj8dawoWI9DMn0dWIKq91ztsuby1yZ+VJ+DQ==]
```
Se pueden añadir todos los usuarios que se deseen indicando su `ROL` (por defecto es `ROLE_ADMIN`) y la `contraseña codificada`. Para codificar la contraseña se ha creado un formulario que recibe una contrasña y devuelve el hash de la contaseña con la codificación necesaria. Por ejemplo, para añadir el usuario `admin2` con la contraseña `admin2`:

1. Se codifica la contraseña en la ruta `/admin/generate?pass=admin2`
2. Se introduce la contraseña en el formulario
3. Se obtendrá el siguiente hash:`C5/xhIS01LWZp6AdjKAM1F7ircenGiaCUdhiXFt2TaFYLyI6KG+1/DJv2QDimFX6PS2hFc3hLqLCdSVph5YmfQ==`
4. Se añade al archivo de configuración `config\settings.yml`:


```yml
users:
    admin:  [ROLE_ADMIN, lOCBXsYmQttwqQiqt7phHmF3uhC9JD6E7IYiipZ9V5CmEJaaKmnj8dawoWI9DMn0dWIKq91ztsuby1yZ+VJ+DQ==]
    admin2: [ROLE_ADMIN, C5/xhIS01LWZp6AdjKAM1F7ircenGiaCUdhiXFt2TaFYLyI6KG+1/DJv2QDimFX6PS2hFc3hLqLCdSVph5YmfQ==]
```

##Gestión de paquetes y dependencias
###PHP
Para la instalación de librerias de PHP se utiliza **composer**. Las dependencias están definidas en el archivo `composer.json` y por defecto se instalan en el directorio `vendor`.

###Assets y librerias front-end
Se utiliza **bower**. Las dependencias están definidas en el archivo `bower.json` y por defecto se instalan en el directorio `web\components`.

##Deploy de la aplicación
Para hacer el proceso mas sencillo, se ha configurado **Subversion** en el servidor de producción. Por lo que para actualizar los cambios de la aplicación tan solo hay que ejecutar los siguientes comandos desde el directorio principal de la aplicación:

1. `svn update`
2. `php composer.phar install` por si hay que instalar paquetes que faltan
3. `bower install` por si hay que instalar librerias que faltan.
4. Borrar el directorio `var\cache\twig` para que no haya problemas de cache con las plantillas de twig.


