#!/bin/sh

# Arquitecturas virtuales: prácticas con vSphere 5.x ESXi
# Script 7.3: Creación de un linked clone de una VM existente en cli

# Incluir funciones auxiliares.

funfile=`dirname $0`/script_functions.sh
if ( ! test -f $funfile )
then
	echo "Error: No se encuentra script_functions.sh"
	exit 2
else
	#Incluir funciones
	. $funfile
fi

#Directorio donde se ubican las máquinas

DATASTOREPATH=/vmfs/volumes/datastore1/Virtual_Machines

# Mejora 1: Imprimir ayuda de uso si no hay argumentos

uso(){
echo
echo "Uso: $0 Source_VM_Name Clon_VM_Name"
echo
}

# Comprobamos el nº de argumentos

if [ "$#" -ne 2 ];
then
      echo "Número de argumentos erroneos"
      echo
      uso
      exit 2
fi

# Encontrar la ubicación e identificadores de la máquina a copiar
# Comprobar que existe la máquina origen a clonar

if ( exist_vm $1 );
then
      id1=$(get_vmid $1)
else
      echo "Error: No existe la maquina con nombre $1 que desea clonar"
      echo
      exit 1
fi


# Comprobar que no existe la maquina clon

if ( exist_vm $2 );
then
      echo
      echo "Error la maquina destino ya existe"
      exit 1
else
      echo
      echo "Procediendo a clonar la máquina..."
      echo
fi



#Comprobar que la máquina origen tiene uno y sólo un snapshot

snapshot=$(get_value snapshot.numSnapshots $DATASTOREPATH/$1/$1.vmsd)

# En caso de que no tenga ningún snapshot el valor de esa variable será vacio.

if [ -z "$snapshot" ];
then
      echo "Error: La máquina que desea clonar no tiene un único Snapshot"
      echo
      exit 1
fi

# Si la variable no esta vacía y sí tiene snapshot debe ser igual a 1 para proceder.

if [ $snapshot -ne 1 ]; 
then
      echo "Error: La máquina que desea clonar no tiene un único Snapshot"
      echo
      exit 1
fi

# Antes de clonar es importante asegurarnos de que la maquina origen este apagada

estado=$(vim-cmd vmsvc/power.getstate $id1)
echo

if (echo $estado | grep -q 'on' || echo $estado | grep -q 'Suspended');
then
      echo "La máquina se encontraba activa, apagando antes de clonar..."
      vim-cmd vmsvc/power.off $id1
      echo
fi

# Creamos el directorio destino

mkdir -p $DATASTOREPATH/$2

#Copiar los ficheros de definición de la máquina origen a la máquina clon:

# - fichero de configuración: .vmx:

cp $DATASTOREPATH/$1/$1.vmx $DATASTOREPATH/$2/$1.vmx

# - fichero de definición del disco: .vmdk:

cp $DATASTOREPATH/$1/$1-000001.vmdk $DATASTOREPATH/$2/$1-000001.vmdk

# - fichero delta del snapshot

cp $DATASTOREPATH/$1/$1-000001-delta.vmdk $DATASTOREPATH/$2/$1-000001-delta.vmdk

#Sustituir los nombres de ficheros y sus respectivas referencias dentro deestos por el nombre clon 
#¡Atención! Esto requiere un pequeño parsing del contenido  para sustituir aquellos campos de los ficheros de configuración que hacen  referencias a los ficheros.

mv $DATASTOREPATH/$2/$1.vmx  $DATASTOREPATH/$2/$2.vmx
mv $DATASTOREPATH/$2/$1-000001.vmdk $DATASTOREPATH/$2/$2-000001.vmdk
mv $DATASTOREPATH/$2/$1-000001-delta.vmdk $DATASTOREPATH/$2/$2-000001-delta.vmdk

sed -i "s/$1/$2/g" "$DATASTOREPATH/$2/$2.vmx"
sed -i "s/$1.vmxf/$2.vmxf/g" "$DATASTOREPATH/$2/$2.vmx"
sed -i "s/$1.nvram/$2.nvram/g" "$DATASTOREPATH/$2/$2.vmx"
sed -i "s/$1.vmdk/$2-000001.vmdk/g" "$DATASTOREPATH/$2/$2.vmx"

#Cambiar la referencia del “parent disk” del fichero de definición del disco que debe de apuntar al de la máquina origen (en el directorio ..)

sed -i "s|$1.vmdk|$DATASTOREPATH/$1/$1.vmdk|g" "$DATASTOREPATH/$2/$2-000001.vmdk"
sed -i "s|$1-000001-delta.vmdk|$2-000001-delta.vmdk|g" "$DATASTOREPATH/$2/$2-000001.vmdk"

seddelete uuid.bios $DATASTOREPATH/$2/$2.vmx
seddelete uuid.location $DATASTOREPATH/$2/$2.vmx
seddelete sched.swap.derivedName $DATASTOREPATH/$2/$2.vmx
seddelete ethernet*.generatedAddress $DATASTOREPATH/$2/$2.vmx

#Generar un fichero .vmsd (con nombre del clon) en el que se indica que es una máquina clonada.
#Coge un fichero .vsmd de un clon generado con VMware Workstation para ver el formato de este archivo
#Si no se genera el fichero .vmsd, al destruir el clon también se borra el ndisco base del snapshot, lo cual no es deseable ya que pertenece a la máquina origen

touch $DATASTOREPATH/$2/$2.vmsd

echo ".encoding = \"UTF-8\"" >> $DATASTOREPATH/$2/$2.vmsd
echo "cloneOf0 = \"$DATASTOREPATH/$1/$1.vmx\"" >> $DATASTOREPATH/$2/$2.vmsd
echo "numCloneOf = \"1\"" >> $DATASTOREPATH/$2/$2.vmsd
echo "sentinel0 = \"$2-000001-delta.vmdk\"" >> $DATASTOREPATH/$2/$2.vmsd
echo "numSentinels = \"1\"" >> $DATASTOREPATH/$2/$2.vmsd

#Una vez que el directorio clon contiene todos los ficheros necesarios hay que registrar la máquina clon (ESTO ES IMPRESCINDIBLE)

vim-cmd solo/registervm $DATASTOREPATH/$2/$2.vmx

# Obtenemos el id y recargamos para reflejar los cambios al .vmx

id2=$(get_vmid $2)

vim-cmd vmsvc/reload $id2

#Listar todas las máquinas para comprobar que el clon está disponible

echo
echo "Listado de Máquinas Virtuales:"
echo
vim-cmd vmsvc/getallvms
echo

