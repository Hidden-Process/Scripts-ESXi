
# Arquitecturas Virtuales 2019/20

## Scripts ESXi 5.X

Automatización de la gestión de máquinas virtuales para ESXi 5.X mediante scripts con herramientas CLI proporcionadas por VMWare.

###  1. Script para la creación de máquinas Virtuales

Script que permite crear una nueva máquina virtual con unas características mínima (dummy), susceptible de ser arrancada/apagada desde el cliente vSphere.
En la consola del servidor ESXi, el script se invoca de la siguiente manera: 

``` #./script_7.1.I.sh Nombre Máquina```

El script finaliza, informando del error, en caso de que ya exista una máquina con el mismo nombre.

Mejoras Incluidas en este Script:

 - Imprimir ayuda de uso
 - Especificar el tipo de máquina como segundo argumento
 - Especificar el tamaño del disco como tercer argumento
 - Especificar el número de tarjetas de red como cuarto argumento.

Con lo cual en caso de querer hacer un uso completo de todas las opciones que proporciona este script un ejemplo de uso podría ser el siguiente:

Imaginemos que queremos una máquina virtual que se llame Ubuntu con un disco duro de 10 GB y 2 interfaces de red, el comando para invocarlo quedaría de la siguiente manera:

```#./script_7.1.I.sh Ubuntu ubuntu-64 10 2```


###  2. Script para la destrucción de máquinas Virtuales

Script que permite destruir completamente una máquina virtual existente, pidiendo confirmación antes de proceder al borrado, en caso de que no exista una máquina con el nombre proporcionado en el argumento, el script finalizará     informando del error.
En caso de no introducir correctamente los argumentos requeridos por el script, este mostrará una ayuda de uso.
En la consola del servidor ESXi, el script se invoca de la siguiente manera:

 ``` #./script_7.1.II.sh Nombre Máquina```

Un ejemplo de uso podría consistir en borrar la maquina creada con el anterior script para ello invocamos lo siguiente:

```#./script_7.1.II.sh Ubuntu```

###  3. Script para la creación de un *full clone*

Como es observable desde el interfaz de vSphere no existe la opción para la creación de clones, esta solo está disponible en el software vCenter, para solucionar esto, este script permite crear un *full clone* de una máquina virtual ya existente, el script antes de copiar recursivamente el contenido de la máquina original al nuevo directorio de la máquina clon y realizar los cambios necesarios en el archivo de confiracion (.vmx) se asegura de que existe la maquina origen y de que no existen la máquina destino, en alguno de estos casos, el script finalizará informando del error.

En la consola del servidor ESXi, invocamos el script de la siguiente manera:

```#./script_7.2.sh Nombre_Origen Nombre_Destino```

Mejoras Incluidas en este Script:

 - Imprimir ayuda de uso en el caso de que se introduzcan erroneamente los argumentos.
 - Renombrar los ficheros que componen la máquina clon y reconfigurar el fichero .vmx destino.

Un ejemplo de uso podría consistir en clonar la máquina que creamos con el primer script para ello lo invocamos de la siguiente forma:

```#./script_7.2.sh Ubuntu Ubuntu_Clon```

