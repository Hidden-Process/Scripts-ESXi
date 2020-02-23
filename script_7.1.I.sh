#!/bin/sh

# Arquitecturas virtuales: prácticas con vSphere 5.x ESXi
# Script 7.1.I: Creación de una nueva VM con características mínimas desde cero en CLI

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

# Directorio donde se ubicará la maquina

DATASTOREPATH=/vmfs/volumes/datastore1/Virtual_Machines

# Mejora 1: Imprimir una ayuda

uso() {
echo
echo "Uso: $0 Nombre Tipo Tamaño NIC"
echo
echo "Script para la creación de máquinas virtuales con las siguientes opciones:"
echo
echo "1º Argumento: Nombre de la Máquina Virtual"
echo
echo "2º Argumento: Tipo de Máquina, a continuación algunos de los soportados:"
echo
echo "Para Windows:     windows7, windows7-64, windows8, windows8 -64, winXPHome, winXPPro, winXPPro-64, winVista, win95, win98"
echo "Para Linux:       ubuntu, ubuntu-64, rhel7, fedora, centos7"
echo "Para VMware/ESXi: vmkernel"
echo
echo "3º Argumento: Capacidad del disco duro en GB" 
echo
echo "4º Argumento: Número de Tarjetas de Red"
echo
echo "--------------------------------------------------------------------------------------------------------------------------"
echo
}

uso

# Comprobamos el nº de argumentos

if [ $# -lt 1 ];
then
      echo "Error: Número de argumentos erroneos"
      echo
      exit 2
fi


#Comprobar si existe una maquina con el mismo nombre, si ya existe salimos del script  y si no la creamos.

if ( exist_vm $1 );
then
      echo "Error: Ya existe una maquina virtual con nombre $1"
      echo
      exit 1
else
      vim-cmd vmsvc/createdummyvm $1 $DATASTOREPATH/$1/$1.vmx
fi

# Mejora 2: Especificar el tipo de maquina como segundo argumento

id=$(get_vmid $1)

if [ $# -gt 1 ];
then
      sed -i "s/other/$2/g" "$DATASTOREPATH/$1/$1.vmx"
      vim-cmd vmsvc/reload $id
fi

# Mejora 3: Especificar el tamaño del disco como tercer argumento
# El archivo .vmdk contiene la configuración del disco, el contenido se encuentra en -flat.vmdk

if [ $# -gt 2 ];
then
       echo
       echo "Creando disco duro con tamaño $3GB" 
       echo
       vmkfstools -X  $3G $DATASTOREPATH/$1/$1.vmdk
       echo
       du -sh $DATASTOREPATH/$1/$1-flat.vmdk
       vim-cmd vmsvc/reload $id
fi

# Mejora 4: Especificar el número de tarjetas como cuarto argumento.

# E1000 vs VMXNET3 Son los 2 principales adaptadores de red disponibles
# Elegimos VMXNET3 debido a que ofrece un rendimiento superior tras la instalacion de las VMWare Tools.
# El E1000 es una emulación por software de una tarjeta de 1GB  y VMXNET3 es un NIC completamente virtualizado de 10GB 
# Más información en: https://www.lewan.com/blog/choosing-the-right-vmware-nic-should-you-replace-your-e1000-with-the-vmxnet3

uuidgen(){

uuid=$(od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}')

p1=${uuid:0:2}
p2=${uuid:2:2}
p3=${uuid:4:2}

addr=00:50:56:$p1:$p2:$p3

}

net_card(){

cont=0

# Numero de Nics
t=$1

# Path
dir=$2

while [ $cont -lt $t ];
do
      uuidgen
      echo "ethernet$cont.virtualDev = \"vmxnet3\"" >> $dir
      echo "ethernet$cont.networkName = \"VM_Network_$cont\"" >> $dir
      echo "ethernet$cont.addressType = \"generated\"" >> $dir
      echo "ethernet$cont.generatedAddress = \"$addr\"" >> $dir
      echo "ethernet$cont.generatedAddressOffset = \"0\"" >> $dir
      echo "ethernet$cont.present = \"TRUE\"" >> $dir
      
      let cont=cont+1
done

}

if [ $# -gt 3 ];
then
      net_card "$4" "$DATASTOREPATH/$1/$1.vmx"
      vim-cmd vmsvc/reload $id
fi

#Listar todas las máquinas para comprobar que se ha creado

echo
echo "Listado de Máquinas Virtuales:"
echo
vim-cmd vmsvc/getallvms
echo

