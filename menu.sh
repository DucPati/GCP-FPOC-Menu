#!/bin/bash
cd ~ #Set current directory
#Set colour variables
Black='\'033'\e'[30m
Red='\'033'\e'[31m
Green='\'033'\e'[32m
Brown='\'033'\e'[33m
Blue='\'033'\e'[94m
Purple='\'033'\e'[95m
Cyan='\'033'\e'[36m
Grey='\'033'\e'[37m
Yellow='\'033'\e'[33m

export trialkey=e20a8ece-cccf-4aa7-ab3c-c9c468e97f23:bd5791172c59ad2
export licenseserver=https://fortiflex.ftntlab.org/

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
}

# Function to display the entered variables before proceeding with instance group creation. To be piped to column -t for formatting
ConfirmInstanceGroupVariables () {
echo
echo -e "${Yellow}OPTIONS-SELECTED: "
echo
echo "Instance_Group: $instancegroupname"
echo "Instance_Template: $instancetemplatename"
echo "Region: $region"
echo "Zone: $zone"
}

#Function to create Instance Group
function createInstanceGroup () {
echo -e "${Red}Creating Instance Group...${Yellow}"
gcloud compute instance-groups managed create $instancegroupname \
--region=$region \
--template=$instancetemplatename \
--zones=$zone \
--size=0
echo -e "${Grey}"
read -e -p "Press any key to continue"
}

#Function to resize Instance Group
function resizeInstanceGroup () {
    echo -e "${Grey}"
    read -e -p "Enter number of instances to resize to: " number
    read -e -p "Enter a filter for the Instance Group name. Eg iam: " instancegroupfilter
    echo -e "${Yellow}"
    gcloud compute instance-groups list --filter="name:$instancegroupfilter"
    echo -e "${Grey}"
    read -e -p "Enter Instance Group name: " instancegroupname
    export region=$(gcloud compute instance-groups list --filter="name:$instancegroupname" --format="value(region)")
    echo -e "Region: $region"
    read -e -p "Is this the correct region? (y/n)" yn
    if [ ${yn} == y ]; then
        echo -e "${Red}Resizing Instance Group to $number instances...${Yellow}"
        gcloud compute instance-groups managed resize $instancegroupname --size=$number --region=$region
    fi
    echo -e "${Grey}"
    read -e -p "Press any key to continue."
}

#Function to Gcloud SSH to config pods with trial key and restart poc
function gcppoclaunch () {
    gcloud compute ssh admin@$1 --zone=$zone --project "cse-projects-202906" --command "register trial $trialkey"
    gcloud compute ssh admin@$1 --zone=$zone --project "cse-projects-202906" --command "set license $licenseserver"
    gcloud compute ssh admin@$1 --zone=$zone --project "cse-projects-202906" --command "poc launch $pocnum"
}

#Function to register trial key on instances in an Instance Group
#This is to ensure unique licenses to avoid license errors during workshops
#Instance will reboot after trial license code is applied
function registerTrialKey () {
    echo -e "${Grey}"
    read -e -p "Enter Instance Group Name: " instancegroupname
    export instancegroupname=$instancegroupname
    echo
    echo -e "${Blue}1. https://license.ftntlab.org/"
    echo -e "2. https://fortiflex.ftntlab.org/ ${Grey}"
    echo
    read -e -p "Select license server: " licenseserverselection
    case $licenseserverselection in
        1) export licenseserver=https://license.ftntlab.org/;;
        2) export licenseserver=https://fortiflex.ftntlab.org/;;
    esac
    echo
    read -e -p "Enter POC number to launch: " pocnum
    export pocnum=$pocnum
    echo -e "Selected Options:"
    echo
    echo -e "${Yellow}Instance Group $instancegroupname"
    echo -e "Trial Key: $trialkey"
    echo -e "License Server: $licenseserver"
    echo -e "POC number ro launch: $pocnum${Grey}"
    echo
    read -e -p "Is this correct? (y/n)" yn
    if [ ${yn} == y ]; then
        export -f gcppoclaunch
        parallel \
            --jobs 5 \
            --joblog logs/logfile-$(date +%Y%m%d%H%M%S) -j 100 \
            gcppoclaunch  ::: $(gcloud compute instance-groups managed list-instances $instancegroupname --region=$region | awk '{ printf $1 "\n" }' | tail -n +2)
        echo -e "${Grey}"
        read -e -p "Press any key to continue"
    fi
}

#Function to set region and other parameters
function setRegion () {
                clear
                echo
                echo -e "${Yellow}1. AU - australia-southeast1 (Sydney)"
                echo -e "2. AS - asia-southeast1 (Singapore)"
                echo -e "3. EU - europe-west1 (Belgium)${Purple}"
                echo
                read -e -p "Make Region Selection. Network and subnet will be automatically configured: " selectregion
                case $selectregion in
                    1)
                        echo -e "${Red}"
                        gcloud config set compute/region australia-southeast1
                        export region=australia-southeast1
                        export network=anz-pgalligan-network-1
                        export subnet=australia-southeast-1
                        export zone=australia-southeast1-b
                        echo -e "${Grey}";;
                    2)
                        echo -e "${Red}"
                        gcloud config set compute/region asia-southeast1
                        export region=asia-southeast1
                        export network=iam-apac-xperts-sin
                        export subnet=iam-apac-xperts-sin
                        export zone=asia-southeast1-b
                        echo -e "${Grey}";;
                    3)
                        echo -e "${Red}"
                        gcloud config set compute/region europe-west1
                        export region=europe-west1
                        export network=iam-eu-vpc
                        export subnet=iam-eu-west1
                        export zone=europe-west1-b
                        echo -e "${Grey}";;
                esac
                echo
                echo -e "${Yellow}Region: ${Grey}$region"
                echo -e "${Yellow}Network: ${Grey}$network"
                echo -e "${Yellow}Subnet: ${Grey}$subnet"
                echo -e "${Yellow}Zone: ${Grey}$zone"
                echo
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


#Set some default Google Cloud parameters
echo -e "${Red}"
gcloud config set project cse-projects-202906
echo -e "${Grey}"
gcloud config get project
setRegion

#Start Menu
while true; do
    clear
    echo
    echo -e "${Purple}IAM CSE Team Google Cloud Tools"
    echo
    echo -e "${Blue}Region: ${Yellow}$region ${Grey}- ${Blue}Zone: ${Yellow}$zone ${Grey}- ${Blue}Network: ${Yellow}$network ${Grey}- ${Blue}Subnet: ${Yellow}$subnet"
    echo
    echo -e "${Grey}1.  Check current Google Cloud Credentials"
    echo "2.  List Disk Images"
    echo "3.  List VM Instances"
    echo "4.  List VM Instance Templates"
    echo "5.  List VM Instance Groups"
    echo "6.  List Public IPs for all instances in an Instance Group"
    echo "7.  Create new Instance Template (source disk image must already exist)"
    echo "8.  Create new Instance Group (Instance Template must already exist)"
    echo "9.  Resize Instance Group"
    echo "10. Prepare Instances for workshop - Register FPOC key, re-launch POC and retrieve unique licenses from license server"
    echo "S.  Set Region"
    echo -e "${Red}Q.  Quit and terminate SSH Session. De-auths from Google Cloud.${Grey}"
    echo
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
        9)
            resizeInstanceGroup;;
        10)
            echo -e "${Grey}"
            read -e -p "Enter a filter for the Instance Group name. Eg iam: " instancegroupfilter
            echo -e "${Yellow}"
            gcloud compute instance-groups list --filter="name:$instancegroupfilter"
            echo -e "${Grey}"
            read -e -p "Press any key to continue"
            registerTrialKey;;
        S)
            setRegion;;
        s)
            setRegion;;
        Q)
            gcloud auth revoke
            exit;;
        q)
            gcloud auth revoke
            exit;;
    esac
done
exit 0