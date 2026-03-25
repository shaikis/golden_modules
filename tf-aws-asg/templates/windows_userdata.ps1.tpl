<powershell>
# Retrieve instance-id for unique hostname
$InstanceId = (Invoke-WebRequest -Uri "http://169.254.169.254/latest/meta-data/instance-id" -UseBasicParsing).Content
$ShortId    = $InstanceId.Replace("i-","").Substring(0,8)
$NewName    = "${hostname_prefix}-$ShortId"

# Rename computer (takes effect after reboot)
Rename-Computer -NewName $NewName -Force

# Tag this instance in AWS
$Region = (Invoke-WebRequest -Uri "http://169.254.169.254/latest/meta-data/placement/region" -UseBasicParsing).Content
& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" ec2 create-tags `
    --region $Region `
    --resources $InstanceId `
    --tags Key=Name,Value=$NewName Key=Hostname,Value=$NewName

%{ if domain_name != "" }
# Domain join using credentials stored in Secrets Manager
$SecretValue = (& "C:\Program Files\Amazon\AWSCLIV2\aws.exe" secretsmanager get-secret-value `
    --region $Region `
    --secret-id "${domain_join_secret}" `
    --query SecretString `
    --output text) | ConvertFrom-Json
$DomainUser = "$($SecretValue.username)@${domain_name}"
$DomainPass = ConvertTo-SecureString $SecretValue.password -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential($DomainUser, $DomainPass)
Add-Computer -DomainName "${domain_name}" -Credential $Cred -Restart -Force
%{ else }
Restart-Computer -Force
%{ endif }

${extra_commands}
</powershell>
<persist>true</persist>
