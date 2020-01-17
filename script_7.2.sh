#!/bin/sh

# Arquitecturas virtuales: prácticas con vSphere 5.x ESXi
# Script 7.2: Creación de un full clone de una VM existente en cli

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

# Copiamos recursivamente el contenido del directorio origen a su destino

cp -r $DATASTOREPATH/$1/* $DATASTOREPATH/$2

# Mejora 2: Renombrar los ficjeros que componen la máquina:

# Renombramos los archivos, sustituyendo el nombre original por el nombre del clon.

mv $DATASTOREPATH/$2/$1.vmx  $DATASTOREPATH/$2/$2.vmx
mv $DATASTOREPATH/$2/$1.vmdk $DATASTOREPATH/$2/$2.vmdk
mv $DATASTOREPATH/$2/$1.vmsd $DATASTOREPATH/$2/$2.vmsd
mv $DATASTOREPATH/$2/$1.vmxf $DATASTOREPATH/$2/$2.vmxf
mv $DATASTOREPATH/$2/$1-flat.vmdk $DATASTOREPATH/$2/$2-flat.vmdk

# Eliminamos este archivo que se copia al nuevo directorio si la maquina origen se inicio alguna vez ,ya que es un archivo que se crea automaticamente al iniciar una máquina y contiene el estado guardado de la BIOS de la máquina virtual

rm -f  $DATASTOREPATH/$2/$1.nvram

# Modificamos el archivo de configuracion(.vmx) para configurar los parametros necesarios para que la máquina funcione correctamente.

sed -i "s/$1/$2/g" "$DATASTOREPATH/$2/$2.vmx"
sed -i "s/$1.vmxf/$2.vmxf/g" "$DATASTOREPATH/$2/$2.vmx"
sed -i "s/$1.nvram/$2.nvram/g" "$DATASTOREPATH/$2/$2.vmx"
sed -i "s/$1-flat.vmdk/$2-flat.vmdk/g" "$DATASTOREPATH/$2/$2.vmdk"

# Registar la máquina clon 

vim-cmd solo/registervm $DATASTOREPATH/$2/$2.vmx

# Obtenemos el id y recargamos para reflejar los cambios al .vmx

id2=$(get_vmid $2)

vim-cmd vmsvc/reload $id2

# Listar todas las máquinas para comprobar que el clon está disponible

echo
echo "Listado de Máquinas Virtuales:"
echo
vim-cmd vmsvc/getallvms
echo

