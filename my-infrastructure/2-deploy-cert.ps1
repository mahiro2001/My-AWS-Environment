# ========================================================
# Step 2: ACM Certificate Deployment (us-east-1)
# ========================================================

# 1. Load environment variables
if (Test-Path .env) {
    Get-Content .env | Where-Object { $_ -match '=' } | ForEach-Object {
        $name, $value = $_.Split('=', 2)
        Set-Variable -Name $name.Trim() -Value $value.Trim() -ErrorAction SilentlyContinue
    }
} else {
    Write-Error "Error: .env file not found. Please copy .env.example to .env and set your DOMAIN_NAME."
    exit 1
}

# 2. Validate Configuration
if ([string]::IsNullOrWhiteSpace($DOMAIN_NAME) -or $DOMAIN_NAME -eq "example.com") {
    Write-Error "Error: DOMAIN_NAME is invalid ($DOMAIN_NAME). Please update your .env file."
    exit 1
}

$STACK_NAME = "devhub-cert"
$ZONE_STACK_NAME = "devhub-zone" 

Write-Host "Configuration Loaded:"
Write-Host "  Domain: $DOMAIN_NAME"
Write-Host "  Stack:  $STACK_NAME"
Write-Host "  Zone Stack (Step 1): $ZONE_STACK_NAME"
Write-Host ""

# 3. Check if Step 1 Stack exists and is healthy
Write-Host "Checking if Step 1 ($ZONE_STACK_NAME) exists and is healthy..."
$STEP1_STATUS = aws cloudformation describe-stacks --stack-name $ZONE_STACK_NAME --query "Stacks[0].StackStatus" --output text 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Error "Error: Step 1 stack '$ZONE_STACK_NAME' does not exist."
    Write-Error "Please run '1-deploy-zone.ps1' first to create the Hosted Zone."
    exit 1
}

Write-Host "Fetching HostedZoneId from Step 1 stack..."
# Fetch the export value from Step 1 (which might be in a different region, e.g., Tokyo)
# Note: We don't specify --region here so it uses the user's default (where Step 1 likely is)
$HOSTED_ZONE_ID = aws cloudformation describe-stacks --stack-name $ZONE_STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='HostedZoneId'].OutputValue" --output text 2>$null

if (-not $HOSTED_ZONE_ID -or $HOSTED_ZONE_ID -eq "None") {
    Write-Error "Error: Could not retrieve HostedZoneId from stack '$ZONE_STACK_NAME'."
    Write-Error "Ensure Step 1 is deployed and outputs a HostedZoneId."
    exit 1
}

# 4. Check for existing ROLLBACK_COMPLETE state in Step 2 stack
Write-Host "Checking if Step 2 ($STACK_NAME) exists in us-east-1..."
$STEP2_STATUS = aws cloudformation describe-stacks --stack-name $STACK_NAME --region us-east-1 --query "Stacks[0].StackStatus" --output text 2>$null

if ($STEP2_STATUS -eq "ROLLBACK_COMPLETE") {
    Write-Warning "Warning: The stack '$STACK_NAME' is in ROLLBACK_COMPLETE state from a previous failed attempt."
    Write-Host "Cleaning up the failed stack to allow a fresh deployment..."
    
    aws cloudformation delete-stack --stack-name $STACK_NAME --region us-east-1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  Waiting for stack deletion to complete..."
        aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME --region us-east-1
        Write-Host "  Stack deleted successfully. Proceeding with deployment."
    } else {
        Write-Error "Error: Failed to delete the rollback stack. Please delete '$STACK_NAME' manually in AWS Console (us-east-1)."
        exit 1
    }
}

Write-Host "Step 2 Status: $STEP2_STATUS (New or Updating)"
Write-Host "--------------------------------------------------------"

Write-Host "Deploying Certificate stack to us-east-1..."
# Execute deployment and capture output/errors
# removing 2>$null to see errors
try {
    aws cloudformation deploy `
      --template-file 2-certificate.yaml `
      --stack-name $STACK_NAME `
      --region us-east-1 `
      --parameter-overrides DomainName=$DOMAIN_NAME HostedZoneId=$HOSTED_ZONE_ID `
      --capabilities CAPABILITY_IAM 2>&1 | Tee-Object -Variable AWS_OUTPUT
} catch {
    Write-Error "An unexpected error occurred during execution: $_"
    exit 1
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "Deployment command sent successfully."
} else {
    Write-Error "Deployment failed with exit code $LASTEXITCODE"
    Write-Host "--------------------------------------------------------"
    Write-Host "AWS CLI Error Details:"
    $AWS_OUTPUT | ForEach-Object { Write-Host $_ }
    Write-Host "--------------------------------------------------------"
    Write-Host "Common causes:"
    Write-Host "- DNS validation timed out (Is the domain pointing to the Route 53 NS records?)"
    Write-Host "- Step 1 stack was deleted or failed"
    Write-Host "- Permissions issues or Region mismatch"
}
