# GCP-FPOC-Menu Overview
GCP Tools for FortiPOC deployment for IAM CSE team.

- Intended to be used when unable to get FNDN team to provision HOLs
- Uses GCP's built-in automation capability
- Prompts for region during startup and automatically configures zone, network and subnet
- Launched from Ubuntu instance in Azure. Accessible via FortiPAM HA cluster in Azure
- FortiPAM HA Cluster in Azure also has option to monitor logs during "FortiPOC Instance Preparation" using the [*logview* ](README.md#logview-user-and-script)user

## FortiPOC HOL Preparation Process
### Disk Image
Create disk image in GCP of the FortiPOC HOL. Make note of the number of the POC that you wish to be launched when all the instances are spun up.

### Instance Template
The GCP Instance Template contains all the parameters to spin up an instance using the disk image you have created as the source. Parameters such as region, zone, network, subnet and source image are required. The menu option to create an Instance Template will request any required information.

### Instance Group
The GCP Instance Group automates the creation of *x* number of instances using the specified Instance Template.

### FortiPOC Instance Preparation
Instances need to be prepared to ensure they use unique licenses. If they don't, the FortiProduct will display license errors during the HOL when FortiGuard determines licenses are being shared amongst VMs. The Instance Preparation will re-register the FortiPOC instance with the FortiPOC Registration Server, obtaining a unique FortiPOC serial number. This unique FortiPOC serial number ensures that when the instance requests a license from the configured FortiPOC license server, it gets a unique license. Once this instance preparation is complete, the script will re-launch the specific POC - it is at this point that the FortiPOC instance requests the licenses.

## Logview User and Script
The *logview* user automatically launches a script which will monitor the logfile created during "FortiPOC Instance Preparation". You will be required to enter the logfile name. The login script will display the available logfiles.