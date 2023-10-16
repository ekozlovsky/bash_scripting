#!/bin/bash
# Created by Yauhen_Kazlouski ekozlovsky@yandex.ru
# Usage:
# Set up kubectl and run script
#
echo "--- getting obgects from kubernetes cluster ---"
# fill in needed namespaces
nameSpaces=("qa" "dex" "echoserver" "gitlab-runner" "ingress-nginx" "keycloak" "keycloak-service" "kube-node-lease" "kube-public" "kube-system" "loki" "monitoring" "sentry" "vault-infra")
currentHM=$(date +%H%M)
folder="secrets"$currentHM
mkdir $folder
fullList=$folder"/full_list${currentHM}.yaml"
# filteredList=$folder"/filtered_list${currentHM}.yaml"
filteredWoDefault=$folder"/filtered_wo_default${currentHM}.yaml"
resultFile=$folder"/result_secrets_${currentHM}.yaml"

echo "Please find results in "$folder
# echo "--- storing Secrets to ${fullList} ---"
kubectl get secrets -A > ${fullList}

# iterate namespaces and store without helm and heading line
for item in ${nameSpaces[@]}; do
  echo "namespace: "$item
  lines_count=$(kubectl get secrets -n $item -l owner!="helm" | wc -l)
  echo "lines: "$lines_count
  filtered_helm_ns_list=$folder"/secrets_wo_helm_ns_"$item"_"$currentHM
  #echo $filtered_helm_ns_list "<<--------------"
  kubectl get secrets -n $item -l owner!="helm" | tail -n $((lines_count-1)) | awk '{print $1}' >> ${filtered_helm_ns_list} 
done

# default* project-qa-token gitlab-ci-token gitlab-runner* runner*
for item in ${nameSpaces[@]}; do
  filtered_helm_ns_list=$folder"/secrets_wo_helm_ns_"$item"_"$currentHM
  filtered_defaults_ns_list=$folder"/secrets_wo_defaults_ns_"$item"_"$currentHM
  # Below you find filters to grep secrets names with regexp *
  cat ${filtered_helm_ns_list} | grep -v "default*" | grep -v "project-qa-toke*" | grep -v "gitlab-ci-toke*" | grep -v "gitlab-runner-gitlab*" | grep -v "runner*" >  ${filtered_defaults_ns_list}
done

#file lines to array, create output file
for item in ${nameSpaces[@]}; do
  filtered_defaults_ns_list=$folder"/secrets_wo_defaults_ns_"$item"_"$currentHM
  #file in array
  filteredSecretsByNS=($(cat ${filtered_defaults_ns_list}))
  for secret_name in ${filteredSecretsByNS[@]}; do
    result_by_ns_file=$folder"/result_secret_ns_"$item"_"$currentHM".yaml"
    echo "---" >> ${result_by_ns_file}
#    kubectl get secret -n $item --field-selector metadata.name=$secret_name | tail -n 1 >> ${result_by_ns_file}
    kubectl get secret -n $item --field-selector metadata.name=$secret_name -o yaml >> ${result_by_ns_file}
  done
done