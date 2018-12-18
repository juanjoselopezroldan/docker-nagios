## Nagios 4

Nagios es un sistema de monitorización de redes ampliamente utilizado, de código abierto, que vigila los equipos (hardware) y servicios (software) que se especifiquen, alertando cuando el comportamiento de los mismos no sea el deseado, ahora exportado a un contenedor para mayor flexibilidad, este contenedor esta haciendo uso concretamente de la versión 4.3.4 de nagios.

Si desea cambiar los parametros confiración para así cambiar las caracteristicas de la imagen, tiene que cambiar los valores directamente en el Dockerfile y posteriormente realizar la creación de la imagen para su uso.
Destacar que la propia imagen lleva incorporada el paquete gcloud y kubectl por si es necesaria la monitorización de clusters de kubernetes ya sean a traves de gcloud para su autenticación o no.

En el Dockerfile se indican los directorios a los que podremos dar persistencia por si deseamos mantener los datos si se da el caso en el que se cae el pod, para así no perder la información del contenedor. Los directorios a los que le podremos dar persistencia son los siguientes:
<dl>
<dd> * "/opt/nagios/var": Si le damos persistencia a este directorio permitiremos mantener datos como los registros de logs de nagios, ademas de los registros de logs su herramienta ndo2db (ndoutils) que sirve para registrar la monitorización a cada instante en una base de datos MySQL</dd>
<dd> * "/opt/nagios/etc": Si le damos persistencia a este directorio podremos mantener los datos de configuración de nagios y de ndoutils, ya que no solo se almacenan en este directorio los datos de configuración, si no que tambien almacenaremos la configuración de los nodos a monitorizar que estarán todos almacenado en un directorio llamado "conf" que es un directorio que se encuentra dentro de este etc </dd>
<dd> * "/opt/Custom-Nagios-Plugins": Si le damos persistencia a este directorio podremos salvar los plugins que le configuraremos a nagios de forma personalizada, así, si se nos cae el contenedor, podremos tener esta información a salvo</dd>
<dd> * "/opt/nagiosgraph/var": Este directorio permitira almacenar los registros de logs de las graficas que nos ofrece nagios</dd>
<dd> * "/opt/nagiosgraph/etc": Este directorio nos permitirá almacenar la configuración que tenemos para la representación en las graficas que nos ofrece nagios con este plugin de NagiosGraph</dd>
</dl>

Una vez teniendo claro para que sirve cada uno de los directorio por el cual le podemos dar persistencia, dentro del directorio "data" se encuentra los ficheros que serán copiados en el proceso de construcción de la imagen cuando le realicemos el build. Este directorio contiene 3 subdirectorio que dividen la parte de configuración de la gestión de procesos de cada uno de los servicios que son iniciados en esta imagen (etc), la parte de la configuración de nagios y nagiosgraph que seran almacenada en el directorio de "/opt/nagios/etc" (opt) y por ultimo el script que será el encargado de iniciar todos los servicios dentro de la imagen, cuyo script puede ser editado a gusto de cada uno llegando a ser lo mas personalizable posible en cada caso, incluyendo la gestión de tarear programados en el crontab dentro del mismo contenedor teniendo como ejemplo cuatro tareas programadas de paradas de proceso de nagios y ndoutils y su correspondiente inicio de nuevo para una actualización de la configuración de los nodos a monitorizar (usr).

Cabe destacar que este script denominado "start_nagios" que se encuentra dentro del directorio "usr" se encargará de mantener siempre el proceso de nagios iniciado, por lo que si se da el caso que la configuración de nagios no es la correcta y no se inicia nagios, este script se encargará de intentar iniciarlo continuamente.

Ademas de ello si deseamos realizar el inicio de la imagen a traves del Docker-compose, podremos realizarlo de forma manual o de forma mas automatizada gracias al fichero Makefile que posee este repositorio (parametros como el nombre de la imagen que se encuentran especificados en del Docker-compose se pueden cambiar a gusto del usuario). Si hacemos uso del Docker-compose, ademas de iniciarnos la imagen previamente construida, tambien nos iniciará un contenedor con mysql que estará conectado con nagios para almacenar los registros de monitorizacion en base de datos.

En el caso que deseemos hacer uso del fichero Makefile, dicho fichero desempeña dos funcionalidades que son el inicio del contenedos usando el docker-compose y la creación de la imagen a partir del Dockerfile.

Por ultimo comentar que el directorio denominado volumes, es el directorio que está predefinido dentro del docker-compose para que se comporte como volumen de los diferentes directorios mencionados anteriormente.
