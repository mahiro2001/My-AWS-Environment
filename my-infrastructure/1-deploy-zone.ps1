# ========================================================
# Step 1: Hosted Zone Deployment
# ========================================================

# Load environment variables from .env file
if (Test-Path .env) {
    Get-Content .env | Where-Object { $_ -match '=' } | ForEach-Object {
        $name, $value = $_.Split('=', 2)
        Set-Variable -Name $name.Trim() -Value $value.Trim()
    }
} else {
    Write-Error "Error: .env file not found. Please copy .env.example to .env and set your DOMAIN_NAME."
    exit 1
}

# Validate DOMAIN_NAME
if (-not $DOMAIN_NAME -or $DOMAIN_NAME -eq "example.com") {
    Write-Warning "Warning: DOMAIN_NAME is not set or still default 'example.com'. Please check your .env file."
    # We don't exit here to allow testing, but in production you might want to exit.
}

$STACK_NAME = "devhub-zone"

Write-Host "Deploying Hosted Zone stack: $STACK_NAME for domain: $DOMAIN_NAME..."

aws cloudformation deploy `
  --template-file 1-hosted-zone.yaml `
  --stack-name $STACK_NAME `
  --parameter-overrides DomainName=$DOMAIN_NAME `
  --capabilities CAPABILITY_IAM

if ($LASTEXITCODE -eq 0) {
    Write-Host "--------------------------------------------------------"
    Write-Host "Deployment Complete."
    Write-Host "Next Steps:"
    Write-Host "1. Go to AWS Route 53 Console."
    Write-Host "2. Find the Hosted Zone for $DOMAIN_NAME."
    Write-Host "3. Copy the 4 Name Servers (NS records)."
    Write-Host "4. Update your domain registrar (e.g. Onamae.com) with these Name Servers."
    Write-Host "5. Wait for DNS propagation."
    Write-Host "6. Run '2-deploy-cert.ps1'."
    Write-Host "--------------------------------------------------------"
} else {
    Write-Error "Deployment failed with exit code $LASTEXITCODE"
}
