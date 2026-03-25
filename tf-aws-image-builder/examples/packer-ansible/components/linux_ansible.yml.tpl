name: RunAnsibleFromS3
description: Download Ansible playbooks from S3 and execute site.yml
schemaVersion: 1.0
phases:
  - name: build
    steps:
      - name: InstallAnsible
        action: ExecuteBash
        inputs:
          commands:
            - dnf install -y ansible-core || yum install -y ansible-core || pip3 install ansible
            - ansible --version

      - name: DownloadPlaybooks
        action: S3Download
        inputs:
          - source: s3://${s3_bucket}/${s3_prefix}/
            destination: /opt/ansible/
            recursive: true

      - name: InstallRequirements
        action: ExecuteBash
        inputs:
          commands:
            - ansible-galaxy install -r /opt/ansible/requirements.yml || true

      - name: RunPlaybook
        action: ExecuteBash
        inputs:
          commands:
            - ansible-playbook /opt/ansible/playbooks/site.yml -c local -i "localhost," -v

  - name: validate
    steps:
      - name: ValidateAnsibleRan
        action: ExecuteBash
        inputs:
          commands:
            - test -f /etc/ansible_done && echo "Ansible completed successfully" || echo "Warning: Ansible marker not found"
