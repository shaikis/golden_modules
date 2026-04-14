param()

$ErrorActionPreference = "Stop"

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
  throw "AWS CLI is required to delete a SQL Server Developer custom engine version."
}

$region = $env:AWS_REGION
$engine = $env:CEV_ENGINE
$engineVersion = $env:CEV_ENGINE_VERSION

if (-not $region -or -not $engine -or -not $engineVersion) {
  exit 0
}

$status = aws rds describe-db-engine-versions `
  --engine $engine `
  --engine-version $engineVersion `
  --region $region `
  --query "DBEngineVersions[0].Status" `
  --output text 2>$null

if ($LASTEXITCODE -ne 0 -or $status -eq "None" -or [string]::IsNullOrWhiteSpace($status)) {
  exit 0
}

Write-Host "Deleting SQL Server Developer custom engine version $engineVersion from $region..."

aws rds delete-custom-db-engine-version `
  --engine $engine `
  --engine-version $engineVersion `
  --region $region | Out-Null

if ($LASTEXITCODE -ne 0) {
  throw "Failed to delete SQL Server Developer custom engine version $engineVersion."
}
