#!/bin/bash
# by Yauhen Kazlouski ekozlovsky@yandex.ru
# restart deployments in namespace
# provide filter for deployments in separate file one deployment per line to exclude
os_type=$(uname -a)

if [[ $(echo $os_type | grep "Microsoft") ]]; then
  echo "Microsoft"
  kubectl_cmd="kubectl.exe"
else
  if [[ $(echo $os_type | grep "Linux") ]]; then
    echo "Linux"
    kubectl_cmd="kubectl"
  fi
fi

currentHM=$(date +%H%M)
default_ns="default"
# filter_deployments=("privet" "medved")

# read filter from file
if [ -z "$2" ]; then
  echo "no filter provided, default filter will be used"
  if [ -f default_filter ]; then
    echo "default filter exists, reading..."
    echo "please provide filter to exclude deployments in separate file"
    filter_deployments=($(cat default_filter))
  else
    filter_deployments=("default" "filter")
  fi
else
  if [ -f "$2" ]; then
    echo "read filter from $2"
    filter_deployments=($(cat $2))
  fi
fi

echo "next deployments will be filtered"
for item in ${filter_deployments[@]};do
  echo $item
done

# defaultSecrets=($(cat ${filteredList} | awk '{print $2}' | grep -v "default*"))

#getting namespaces
lines_count=$($kubectl_cmd get ns | wc -l)
namespaces_array=( $($kubectl_cmd get ns | awk '{print $1}' | tail -n $((lines_count-1)) ))

if [ "$#" -eq 0 ]; then
 echo "no arguments provided. usage:"
 echo $0 $default_ns" filter_file"
 echo "AVAILABLE NAMESPACES:"
 for ns in ${namespaces_array[@]};do 
  echo $ns
 done
else
 default_ns=( "$@" )
fi

lines_count=$($kubectl_cmd get deployments -n $default_ns | wc -l)
deployments_array=($($kubectl_cmd get deployments -n $default_ns  | awk '{print $1}' | tail -n $((lines_count-1)) ))

echo "AVAILABLE DEPLOYMENTS IN NAMESPACE $default_ns:"
for deployment in ${deployments_array[@]}; do
  echo $deployment
done

#filter out deployments
for del_element in ${filter_deployments[@]}; do
  deployments_array=("${deployments_array[@]/$del_element}")
done

echo "deployments count "${#deployments_array[@]}
if [ -z "$deployments_array" ]; then
  echo "no deployments, exiting..."
  exit 1
fi


echo "--- filtered deployments to restart---"
for item in ${deployments_array[@]}; do 
  echo "restarting "$item
  $kubectl_cmd rollout restart deployments/$item -n $default_ns
  sleep 10
  $kubectl_cmd rollout status deployments/$item -n $default_ns
done
