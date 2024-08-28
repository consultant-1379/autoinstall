#/bin/bash 
set -x

service puppet stop
service vcs stop

disk_list=$(vxdg list | awk '{print $1}' | sed '1d')
disk_names=()

##For all disk groups
for line in $disk_list; do
   #stop vxvm volumes
   vxvol -g $line stopall 
   #destroy vxvm volumes
   vxdg destroy $line
   disk_names+=($(vxdisk list | grep "$line" | awk '{print $1}'))
done

for line in "${disk_names[@]}"; do
   vxdiskunsetup -Cf $line
done


