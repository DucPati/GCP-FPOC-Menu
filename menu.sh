#!/bin/bash
cd ~ #Set current directory
#Set colour variables
Black='\'033'\e'[30m
Red='\'033'\e'[31m
Green='\'033'\e'[32m
Brown='\'033'\e'[33m
Blue='\'033'\e'[34m
Purple='\'033'\e'[35m
Cyan='\'033'\e'[36m
Grey='\'033'\e'[37m
Yellow='\'033'\e'[33m

#DEFINE FUNCTIONS
#Function to read variables required to create Instance Template
getInstanceTemplateVariables () {
echo -e "${Grey}"
read -e -p "Enter a name for the Instance Template: " instancetemplatename
export instancetemplatename=$instancetemplatename
read -e -p "How many CPUs?: " cpu
export cpu=$cpu
read -e -p "How much RAM? (Include the unit, eg. 80GB ): " ram
export ram=$ram
read -e -p "What size disk? (include the unit, eg. 550GB): " disksize
export disksize=$disksize
echo -e "${Yellow}"
gcloud compute images list --filter="name:iam"
echo -e "${Grey}"
read -e -p "Select one of the above images as the source image. (copy and paste it): " sourcediskimage
export sourcediskimage=$sourcediskimage
echo -e "${Yellow}"
gcloud compute networks list --filter="name:(iam,pgalligan)"
echo -e "${Grey}"
read -e -p "Select one of the above networks. iam-eu-vpc for EMEA workshops (copy and paste it): " network
export network=$network
echo -e "${Yellow}"
gcloud compute regions list --filter="name:(europe,australia)"
echo -e "${Grey}"
read -e -p "Select one of the above regions. europe-west1 for EMEA workshops (copy and paste it): " region
export region=$region
echo -e "${Yellow}"
gcloud compute networks subnets list --filter="network:$network"
echo -e "${Grey}"
read -e -p "Select the subnet. iam-eu-west1 for EMEA workshops (copy and paste it): " subnet
export subnet=$subnet
}

# Function to display the entered variables before proceeding with instance creation. To be piped to column -t for formatting
ConfirmInstanceTemplateVariables () {
echo
echo -e "${Yellow}OPTIONS-SELECTED: "
echo
echo "Instance_Template: $instancetemplatename"
echo "CPUs: $cpu"
echo "RAM: $ram"
echo "Disk-Size: $disksize"
echo "Source-Disk-Image: $sourcediskimage"
echo "Network: $network"
echo "Subnet: $subnet"
echo "Region: $region"
}

#Function to create Instance Template
createInstanceTemplate () {
    echo -e "${Red}Creating Instance Template...${Yellow}"
    gcloud compute instance-templates create $instancetemplatename \
    --network=$network \
    --subnet=$subnet \
    --boot-disk-type=pd-ssd \
    --boot-disk-size=$disksize \
    --image=$sourcediskimage \
    --custom-cpu=$cpu \
    --custom-memory=$ram \
    --custom-vm-type=n1 \
    --region=$region
    echo -e "${Grey}"
    read -e -p "Press any key to continue"
}

#Function to read variables required to create Instance Group
getInstanceGroupVariables () {
echo -e "${Grey}"
read -e -p "Enter a name for the Instance Group: " instancegroupname
export instancegroupname=$instancegroupname
read -e -p "Enter filter for Instance Template name: " instancetemplatefilter
echo -e "${Yellow}"
gcloud compute instance-templates list --filter="name:$instancetemplatefilter"
export instancetemplatefilter=$instancetemplatefilter
echo -e "${Grey}"
read -e -p "Enter Instance Template name: " instancetemplatename
export instancetemplatename=$instancetemplatename
echo -e "${Yellow}"
gcloud compute regions list --filter="name:(europe,australia)"
echo -e "${Grey}"
read -e -p "Select one of the above regions. europe-west1 for EMEA workshops (copy and paste it): " region
export region=$region
}

# Function to display the entered variables before proceeding with instance group creation. To be piped to column -t for formatting
ConfirmInstanceGroupVariables () {
echo
echo -e "${Yellow}OPTIONS-SELECTED: "
echo
echo "Instance_Group: $instancegroupname"
echo "Instance_Template: $instancetemplatename"
echo "Region: $region"
}

#Function to create Instance Group
function createInstanceGroup () {
echo -e "${Red}Creating Instance Group...${Yellow}"
gcloud compute instance-groups managed create $instancegroupname \
--region=$region \
--template=$instancetemplatename \
--target-distribution-shape=even \
--size=0
echo -e "${Grey}"
read -e -p "Press any key to continue"
}

# START SCRIPT ACTIONS
#Revoke any previous Google Cloud authentication session
gcloud auth revoke
clear
echo -e "${Yellow}This is the IAM CSE Google Cloud menu for Workshop HOLs"
echo
echo -e "${Red}You must auth to Google Cloud first. Follow the prompts:${Cyan}"

#Auth to Google Cloud using auth key/code from browser auth
gcloud auth login
echo -e "${Grey}"
clear


#Start Menu
while true; do
    clear
    echo
    echo -e "${Purple}IAM CSE Team Google Cloud Menu"
    echo
    echo -e "${Grey}1. Check GCloud Credentials"
    echo "2. List Disk Images"
    echo "3. List VM Instances"
    echo "4. List VM Instance Templates"
    echo "5. List VM Instance Groups"
    echo "6. List Public IPs for all instances in an Instance Group"
    echo "7. Create new Instance Template (source disk image must already exist)"
    echo "8. Create new Instance Group (Instance Template must already exist)"
    echo -e "${Red}Q. Quit and terminate SSH Session${Grey}"
    read -e -p "Select an option:" menuchoice
    case $menuchoice in
        1)
            echo -e "${Yellow}"
            gcloud auth list
            read -e -p "Press any key to continue"
            echo -e "${Grey}";;
        2)
            echo -e "${Grey}"
            read -e -p "Enter filter for the Disk Image name: " diskimagename
            echo -e "${Yellow}"
            gcloud compute images list --filter="name:$diskimagename"
            echo -e "${Grey}"
            read -e -p "Press any key to continue";;
        3)
            echo -e "${Grey}"
            read -e -p "Enter a filter for the Instance name. Eg iam: " instancefilter
            echo -e "${Yellow}"
            gcloud compute instances list --filter="name:$instancefilter"
            echo -e "${Grey}"
            read -e -p "Press any key to continue";;
        4)
            echo -e "${Grey}"
            read -e -p "Enter a filter for the Instance Template name. Eg iam: " templatefilter
            echo -e "${Yellow}"
            gcloud compute instance-templates list --filter="name:$templatefilter"
            echo -e "${Grey}"
            read -e -p "Press any key to continue";;
        5)
            echo -e "${Grey}"
            read -e -p "Enter a filter for the Instance Group name. Eg iam: " instancegroupfilter
            echo -e "${Yellow}"
            gcloud compute instance-groups list --filter="name:$instancegroupfilter"
            echo -e "${Grey}"
            read -e -p "Press any key to continue";;
        6)
            echo -e "${Grey}"
            read -e -p "Enter a filter for the Instance Group name. Eg iam: " instancegroupfilter
            echo -e "${Yellow}"
            gcloud compute instance-groups list --filter="name:$instancegroupfilter"
            echo -e "${Grey}"
            read -e -p "Enter Instance Group Name: " instancegroup
            echo
            echo -e "Public IPs are: ${Yellow}"
            gcloud compute instances list --filter="name:$instancegroup" | awk '{ printf $5 "\n" }' | tail -n +2
            echo -e "${Grey}"
            read -e -p "Press any key to continue";;
        7)
            getInstanceTemplateVariables
            ConfirmInstanceTemplateVariables | column -t
            echo -e "${Grey}"
            read -e -p "Are these option correct? (yes/no): " yesno
            case $yesno in
                yes)
                    clear
                    echo
                    createInstanceTemplate;;
                no)
                    echo;;
            esac;;
        8)
            getInstanceGroupVariables
            ConfirmInstanceGroupVariables | column -t
            echo -e "${Grey}"
            read -e -p "Are these option correct? (yes/no): " yesno
            case $yesno in
                yes)
                    clear
                    echo
                    createInstanceGroup;;
                no)
                    echo;;
            esac;;
        Q)
            gcloud auth revoke
            exit;;
        q)
            gcloud auth revoke
            exit;;
    esac
done
exit 0