#!/bin/bash


#Get required variables
read -s -p "Enter VM password: " password
export password=$password
echo
read -e -p "Enter SSH port (Eg. 11007): " port
export port=$port
echo
read -e -p "Enter filename to export results to (will be overwritten): " filename
export filename=$filename
echo "Getting License Status..." > $filename

for instance in $(cat instanceips.txt); do
        echo $instance >> logs/$filename
        sshpass -p $password ssh -o StrictHostKeyChecking=no admin@$instance -p $port "get sys status | grep License.Status" >> logs/$filename
done
echo -e 
