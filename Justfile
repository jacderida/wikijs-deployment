#!/usr/bin/env just --justfile

set dotenv-load := true
wiki_domain_name := env_var('WIKI_DOMAIN_NAME')

wiki:
  #!/usr/bin/env bash
  set -e
  cd terraform
  terraform init
  terraform apply -auto-approve
  ip_address=$(terraform output -raw elastic_ip)
  cd ..

  cat <<- EOF > inventory
  [wikijs]
  $ip_address ansible_ssh_private_key_file=~/.ssh/wikijs ansible_ssh_user=ec2-user ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  EOF

  ansible-playbook --inventory inventory provision.yml --extra-vars wiki_domain_name={{wiki_domain_name}}

clean:
  #!/usr/bin/env bash
  set -e
  cd terraform
  terraform destroy -auto-approve
