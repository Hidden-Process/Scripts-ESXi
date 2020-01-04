#!/bin/sh

# Arquitecturas virtuales: prácticas con vSphere 5.x ESXi
# Script 7.1.II: Borrado de una VM existente en CLI

# Incluir funciones que se proporcionan

funfile=`dirname $0`/script_functions.sh
if ( ! test -f $funfile )
then
	echo "Error: No se encuentra script_functions.sh"
	exit 2
else
	#Incluir funciones
	. $funfile
fi

# Directorio donde se ubican las máquinas

DATASTOREPATH=/vmfs/volumes/datastore1/Virtual_Machines

# Mejora 1: Imprimir ayuda si no se introducen argumentos.

uso(){
echo
echo "Uso: $0 Nombre de la maquina"
echo
}

# Comprobamos el nº de argumentos

if [ "$#" -ne 1 ];
then
      echo "Número de argumentos erroneos"
      echo
      uso
      exit 2
fi

# Comprobar si existe la máquina en cuestión
# Si existe nos guardamos su identificador para usarlo más adelante.

if ( exist_vm $1 );
then
      id=$(get_vmid $1)
else
      echo "Error: No existe la maquina con nombre $1 que desea borrar"
      echo
      exit 1
fi


#Solicitar confirmación de borrado

echo "¿Está seguro que desea eliminar la máquina virtual $1 ?"
echo
echo "Responda con SI o NO"
echo


read -p 'Respuesta: ' respuesta

# Toda confirmación que no sea excluvivamente positiva terminara el script.

if [ "$respuesta" = "SI" ];
then
      echo
      echo "Procediendo al borrado de la máquina $1"
else 
      echo
      echo  "Ok, la maquina con nombre $1 se conservara"
      echo
      exit 0 
fi

# Apagar la máquina (Comprobamos su estado previamente)

estado=$(vim-cmd vmsvc/power.getstate $id)
echo

if (echo $estado | grep -q 'on' || echo $estado | grep -q 'Suspended');
then
      echo "La máquina se encontraba activa, apagando antes de eliminar..."
      vim-cmd vmsvc/power.off $id
      echo
fi

# Finalmente Borramos la máquina.

vim-cmd vmsvc/destroy $id

# Listar todas las máquinas para comprobar que se ha borrado

echo "Listado de Máquinas Virtuales:"
echo
vim-cmd vmsvc/getallvms
echo

