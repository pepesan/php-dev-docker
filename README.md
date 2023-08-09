# Entorno de Ejecución de Aplicaciones PHP con Docker y Docker Compose
![Arquitectura](./docs/arquitectura.png)
# Instalación
* Deberás tener instalado:
  * Docker
  * Docker Compose

# Inicialización del Entorno
./pvd.sh init

# Lanzamiento del Entorno
- Usando el comando personalizado: ./pvd.sh start
- Con el Docker compose: docker compose up -d --force-recreate

# URLS de acceso:
* Entorno PHP: http://localhost:80 (deberías ver el phpinfo.php)
* Entorno PHPMyAdmin: http://localhost:8080 (usuario: test/test)

# Parada del Entorno
- Usando el comando personalizado: ./pvd.sh stop
- Con el Docker compose: docker compose down


# Carpetas Importantes:
* src: código php
* conf: fichero de configuración de nginx y PHP
* db-data: volumen de datos de BBDD

# Fichero Dockerfile
Este fichero permite generar una imagen docker para crear 
un entorno PHP-FPM con la versión de PHP específica.
Permite también elegir las extensiones de PHP que necesitemos.
La primera vez que carguen los contenedores con el docker compose, 
Creará la imagen de PHP-FPM, por lo que el primer arranque tarará 
un poco más que el resto de veces

## Entorno Producción
- Usando el comando personalizado: ./pvd.sh start prod
- Con el Docker compose: docker compose -f docker-compose-prod.yaml up -d --force-recreate

## Entorno Moodle
- ./init-moodle.sh # esto crea un enlace a la carpeta moodle desde src
- copia el contenido del fichero moodle.tgz descomprimido a la carpeta moodle
- Usando el comando personalizado: ./pvd.sh start moodle
- Con el Docker compose: docker compose -f docker-compose-prod.yaml up -d --force-recreate
- Entra a [http://localhost/](http://localhost/)
- La bbdd está disponible en:
  - host: db
  - database name: test
  - username: test
  - password: test
- Si necesitas cambiar estos valores vete al fichero docker-compose-moodle.yaml

## Entorno Laravel
- ./pvd.sh init laravel
- Entrar al contenedor php: ./pvd.sh container exec laravel-php /bin/bash
- Dentro del contenedor:
  - Creamos el proyecto
  - /var/www/html# laravel new blog
  - Nos permitirá elegir el starter kit: puedes empezar por Laravel Breeze
  - Only API
  - PHPUnit
  - Esto creará el proyecto en src/blog
  - métete en la carpeta del proyecto: cd blog
  - comprueba que están las dependencias: composer install
  - Cambia los permisos de la carpeta: chown -R www-data:www-data blog
  - genera las claves de Laravel: php artisan key:generate
  - Cambia el fichero .env
    <pre>DB_CONNECTION=mysql
    DB_HOST=db
    DB_PORT=3306
    DB_DATABASE=test
    DB_USERNAME=test
    DB_PASSWORD=test</pre>
  - Aplica el esquema de la bbdd: php artisan migrate
  - esto debería darte una salida similar a la siguiente:
  <code>php artisan migrate
Cannot load Zend OPcache - it was already loaded

INFO  Preparing database.

Creating migration table ............................................................................................................... 18ms DONE

INFO  Running migrations.

2014_10_12_000000_create_users_table ................................................................................................... 30ms DONE
2014_10_12_100000_create_password_reset_tokens_table ................................................................................... 29ms DONE
2019_08_19_000000_create_failed_jobs_table ............................................................................................. 27ms DONE
2019_12_14_000001_create_personal_access_tokens_table .................................................................................. 51ms DONE</code>
  - Lanza la aplicación: php artisan serve
  - Eso debería abrir el puerto 8000 dentro del contenedor: curl http://localhost:8000 
  - Pero debería estar disponible en tu host en [http://localhost:8001/](http://localhost:8001/)



        

