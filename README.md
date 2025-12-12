# Dec 11, 2025

Purchased URL from namecheapa for my AWS project: cloudwithzarapalevani.online. I am aware that I could registere a domain via Route 53 but chose to do so via NameCheap. 

I delegated my domain cloudwithzarapalevani.online from NameCheap to AWS Route 53. This means Route 53 now controls all DNS for my domain instead of NameCheap. By updating the nameservers, I effectively told the internet: “If you need DNS answers for my domain, go to AWS.” This shift gives me full flexibility to route traffic to my cloud resources and manage all DNS records directly inside Route 53. A small but critical step in building a fully cloud-hosted resume stack.

Next, I work on having a one-command, fully reproducible way to create/update my AWS S3 front-end hosting infrastructure using CloudFormation, driven by Ansible, so later I can plug this into CI/CD.

Ansible is an open-source IT automation engine that simplifies complex IT tasks like configuration management, application deployment, and orchestration by describing your infrastructure in simple, declarative YAML files (called playbooks).

After delegating my domain to Route 53, I began building the automation foundation for my Cloud Resume Challenge. The goal is to deploy my front-end hosting infrastructure using CloudFormation, executed through Ansible, with everything version-controlled and reproducible using a single command.
Setting up my infrastructure-as-code workflow
I opened my repository in GitHub Codespaces so I could work inside a Linux environment (required for Ansible). My repository structure now includes an AWS folder that will contain:
```
AWS/
├── template.yaml
├── playbooks/
│   └── deploy.yml
├── vaults/
│   └── prod.yml   (encrypted with Ansible Vault)
└── README.md      (optional, recommended)
```
Installing Ansible in Codespaces
Inside Codespaces, I installed Ansible and the AWS collection required for CloudFormation deployments:

```
sudo apt update
sudo apt install -y ansible python3-boto3
ansible-galaxy collection install amazon.aws
```
I verified installation:
```
ansible --version
ansible-vault --version
```

Creating my CloudFormation template
I created a minimal CloudFormation template at AWS/template.yaml that defines an S3 bucket for my front-end:
```
AWSTemplateFormatVersion: '2010-09-09'
Description: Cloud Resume Challenge - S3 bucket for frontend hosting

Parameters:
  BucketName:
    Type: String

Resources:
  ResumeBucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: !Ref BucketName
    DeletionPolicy: Retain

```
Creating the Ansible playbook
At AWS/playbooks/deploy.yml, I wrote the playbook that applies this CloudFormation stack:
```
- name: Deploy CloudFormation stack for Cloud Resume Challenge
  hosts: localhost
  connection: local
  gather_facts: false

  vars_files:
    - ../vaults/prod.yml

  environment:
    AWS_ACCESS_KEY_ID: "{{ aws_access_key_id }}"
    AWS_SECRET_ACCESS_KEY: "{{ aws_secret_access_key }}"
    AWS_DEFAULT_REGION: "{{ aws_region }}"

  tasks:
    - name: Ensure CloudFormation stack is present
      amazon.aws.cloudformation:
        stack_name: "{{ cfn_stack }}"
        state: present
        region: "{{ aws_region }}"
        template: "{{ playbook_dir }}/../template.yaml"
        template_parameters:
          BucketName: "{{ bucket_name }}"
        disable_rollback: false
        on_create_failure: ROLLBACK
        wait: true
```
Creating AWS credentials for automation
In AWS IAM, I created a machine user:
User: cloud-resume-challenge-machine

Permission: AdministratorAccess (temporary for the project)

Generated:

- Access Key ID
- Secret Access Key
- Storing secrets in an Ansible Vault

I created the unencrypted file first:
```
cat > AWS/vaults/prod.yml
```
Contents:
```
cfn_stack: cloud-resume-challenge
aws_region: us-east-1

aws_access_key_id: <MY_ACCESS_KEY_ID>
aws_secret_access_key: <MY_SECRET_ACCESS_KEY>

bucket_name: cloud-resume-zarapalevani-2025
```
Then I encrypted it:
```
ansible-vault encrypt AWS/vaults/prod.yml
```
This replaced the file contents with AES256-encrypted vault text.
Creating the one-command deploy script
Under AWS/bin/deploy:
```
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${PROJECT_ROOT}"

ansible-playbook --ask-vault-pass AWS/playbooks/deploy.yml "$@"
```
Made it executable:
```
chmod +x AWS/bin/deploy
```
Or via my one-command script:
```
./AWS/bin/deploy
```
This executed CloudFormation through Ansible, creating my S3 bucket inside AWS — the first real piece of my automated Cloud Resume Challenge infrastructure.

I iterated through multiple Ansible and YAML errors (bad playbook syntax, invalid vault YAML, unsupported CloudFormation module parameters, and missing boto3/botocore on the Codespaces Python interpreter). After fixing these one by one, I ran:
```
ansible-playbook --ask-vault-pass AWS/playbooks/deploy.yml
```
The playbook completed successfully with:
```
Stack CREATE complete
```
and CloudFormation now shows a stack named cloud-resume-challenge in CREATE_COMPLETE state, with an S3 bucket resource cloud-resume-zarapalevani-2025. My one-command infra deploy is officially working.

# Dec 12

I proceeded to implement static website hosting on AWS S3 using a repeatable, automation-first approach that aligns with how I plan to deploy the same architecture across Azure and GCP.

Rather than building three separate frontends, I designed a shared frontend with cloud-specific “flavors.” The shared layer contains the core HTML, CSS, and JavaScript, while each cloud provider (AWS, Azure, GCP) has its own JSON configuration file to inject provider-specific text, tooling, and domain details at build time. This allows one codebase to support three cloud providers cleanly, without duplication.

I structured the repository to reflect this design:

- frontend/shared/ — common HTML, CSS, JS
- frontend/flavors/ — provider-specific JSON configs (aws.json, azure.json, gcp.json)
- frontend/dist/ — generated, deployable artifacts per provider
- scripts/ — build automation
- AWS/ — CloudFormation + Ansible infrastructure and deployment logic

To generate the AWS version of the site, I used a build script that:

1. Reads the shared frontend templates
2. Loads the AWS flavor configuration
3. Replaces placeholders with AWS-specific values
4. Outputs a fully static site under frontend/dist/aws/

This approach ensures the frontend is deterministic and reproducible, with no manual edits required per cloud.

On the infrastructure side, I extended my existing Ansible playbook to orchestrate the full AWS deployment workflow:

- Ensure the CloudFormation stack exists (idempotent)
- Build the AWS frontend flavor
- Upload the generated static site to the S3 bucket using aws s3 sync

The deployment was executed from GitHub Codespaces using:
```
ansible-playbook --ask-vault-pass AWS/playbooks/deploy.yml
```
The CloudFormation stack successfully created the S3 bucket, and the Ansible run confirmed the upload of the frontend assets. I verified that the bucket contained the expected files (index.html, error.html, styles.css, app.js) and that the S3 website endpoint correctly served the AWS version of my resume.

At this point:

- Infrastructure is defined as code (CloudFormation)
- Secrets are managed securely (Ansible Vault)
- Frontend builds are automated and provider-aware
- Deployment is repeatable with a single command

This establishes a solid foundation for the next steps: mapping my custom domain to the S3 website endpoint, adding HTTPS via CloudFront, and then replicating the same frontend-and-flavor pattern for Azure and GCP using their native services.