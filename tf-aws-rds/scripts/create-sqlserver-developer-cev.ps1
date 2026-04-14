param()

$ErrorActionPreference = "Stop"

if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
  throw "AWS CLI is required to create a SQL Server Developer custom engine version."
}

$region = $env:AWS_REGION
$engine = $env:CEV_ENGINE
$engineVersion = $env:CEV_ENGINE_VERSION
$bucketName = $env:CEV_BUCKET_NAME
$bucketPrefix = $env:CEV_BUCKET_PREFIX
$description = $env:CEV_DESCRIPTION
$mediaFilesJson = $env:CEV_MEDIA_FILES_JSON
$pollIntervalSeconds = [int]$env:CEV_POLL_INTERVAL
$timeoutSeconds = [int]$env:CEV_TIMEOUT_SECONDS

$mediaFiles = @()
if ($mediaFilesJson) {
  $mediaFiles = @(ConvertFrom-Json -InputObject $mediaFilesJson)
}

function Get-CevStatus {
  $status = aws rds describe-db-engine-versions `
    --engine $engine `
    --engine-version $engineVersion `
    --region $region `
    --query "DBEngineVersions[0].Status" `
    --output text 2>$null

  if ($LASTEXITCODE -ne 0 -or $status -eq "None" -or [string]::IsNullOrWhiteSpace($status)) {
    return $null
  }

  return $status.Trim()
}

$existingStatus = Get-CevStatus

if (-not $existingStatus) {
  Write-Host "Creating SQL Server Developer custom engine version $engineVersion in $region..."

  $createArgs = @(
    "rds", "create-custom-db-engine-version",
    "--engine", $engine,
    "--engine-version", $engineVersion,
    "--database-installation-files-s3-bucket-name", $bucketName,
    "--region", $region
  )

  if ($bucketPrefix) {
    $createArgs += @("--database-installation-files-s3-prefix", $bucketPrefix)
  }

  if ($description) {
    $createArgs += @("--description", $description)
  }

  $createArgs += "--database-installation-files"
  $createArgs += $mediaFiles

  & aws @createArgs | Out-Null

  if ($LASTEXITCODE -ne 0) {
    throw "Failed to create SQL Server Developer custom engine version $engineVersion."
  }
} else {
  Write-Host "SQL Server Developer custom engine version $engineVersion already exists with status: $existingStatus"
}

$deadline = (Get-Date).AddSeconds($timeoutSeconds)

while ((Get-Date) -lt $deadline) {
  $status = Get-CevStatus

  if ($status -eq "available") {
    Write-Host "SQL Server Developer custom engine version $engineVersion is available."
    exit 0
  }

  if ($status -in @("failed", "incompatible-installation-media", "inactive")) {
    $failureReason = aws rds describe-db-engine-versions `
      --engine $engine `
      --engine-version $engineVersion `
      --region $region `
      --query "DBEngineVersions[0].FailureReason" `
      --output text 2>$null

    throw "SQL Server Developer custom engine version $engineVersion entered status '$status'. FailureReason: $failureReason"
  }

  $displayStatus = if ($status) { $status } else { "not-found-yet" }
  Write-Host "Waiting for SQL Server Developer custom engine version $engineVersion. Current status: $displayStatus"
  Start-Sleep -Seconds $pollIntervalSeconds
}

throw "Timed out waiting for SQL Server Developer custom engine version $engineVersion to become available."
