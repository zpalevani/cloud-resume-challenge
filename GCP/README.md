## Install Terraform

We are going to use terraform for IaC with GCP because that is the recommended way to do IaC on GCP despite there being Deployment Manager. We should be able to manage terraform state file with Infsastructure Mnaager. I am on a windows manage so I used https://chocolatey.org/install to install Terraform on my machine. Use Power Shell in Admin mode to install TF. 
```choco install terraform``` to test locall. 
Then I installed via GitHub codespaces: 
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update

sudo apt-get install terraform

Test intallation ```terraform -help```
Check TF version ```terraform --version```
terraform -install-autocomplete


### Terraform and GCP Auth

In GCP we create a new service account and give it infra admin access which for now is should be enough permissions to create the resources we want. 

We need to set the following envot variable and this will allow TF to auth to GCP. 

```sh
export GOOGLE_APPLICATION_CREDENTIALS=/workspaces/cloud-resume-challenge/gcp/gcp-key.json```
```

To perssist this we should add to `bash_profile` or `.bashrc`

reload our bash file
```sh 
vi ~/.bashrc
source ~/ .bashrc
env | grep GOOGLE
```

## Install Ansible

```sh
pipx install --include-deps ansible
```

## set up vault with gcp cred
we'll need store the contents of the gcp key in our vault.
