name: RunAnsibleFromS3Windows
description: Download Ansible playbooks from S3 and execute site.yml on Windows
schemaVersion: 1.0
phases:
  - name: build
    steps:
      - name: InstallPython
        action: ExecutePowerShell
        inputs:
          commands:
            - |
              $pkg = Get-Package -Name "Python*" -ErrorAction SilentlyContinue
              if (-not $pkg) {
                $url = "https://www.python.org/ftp/python/3.11.4/python-3.11.4-amd64.exe"
                Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\python.exe"
                Start-Process "$env:TEMP\python.exe" -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
              }

      - name: InstallAnsible
        action: ExecutePowerShell
        inputs:
          commands:
            - pip install ansible pywinrm

      - name: DownloadPlaybooks
        action: S3Download
        inputs:
          - source: s3://${s3_bucket}/${s3_prefix}/
            destination: C:\ansible\
            recursive: true

      - name: InstallRequirements
        action: ExecutePowerShell
        inputs:
          commands:
            - if (Test-Path C:\ansible\requirements.yml) { ansible-galaxy install -r C:\ansible\requirements.yml }

      - name: RunPlaybook
        action: ExecutePowerShell
        inputs:
          commands:
            - ansible-playbook C:\ansible\playbooks\site.yml -c local -i "localhost," -e "ansible_connection=local" -v

  - name: validate
    steps:
      - name: ValidateAnsibleRan
        action: ExecutePowerShell
        inputs:
          commands:
            - Write-Host "Ansible phase complete"
