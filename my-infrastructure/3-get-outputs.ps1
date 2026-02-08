# ========================================================
# Helper: Get Infrastructure Outputs
# ========================================================
# Run this to get the HostedZoneId and CertificateArn
# needed for your Application deployment.

$ZONE_STACK = "devhub-zone"
$CERT_STACK = "devhub-cert"

Write-Host "Fetching outputs..."
Write-Host "--------------------------------------------------------"

# 1. Get Hosted Zone ID (Default Region)
$HOSTED_ZONE_ID = aws cloudformation describe-stacks --stack-name $ZONE_STACK --query "Stacks[0].Outputs[?OutputKey=='HostedZoneId'].OutputValue" --output text 2>$null
if (-not $HOSTED_ZONE_ID -or $HOSTED_ZONE_ID -eq "None") {
    Write-Warning "HostedZoneId not found (Stack $ZONE_STACK might be missing)"
} else {
    Write-Host "HostedZoneId:   $HOSTED_ZONE_ID"
}

# 2. Get Certificate ARN (us-east-1)
$CERT_ARN = aws cloudformation describe-stacks --stack-name $CERT_STACK --region us-east-1 --query "Stacks[0].Outputs[?OutputKey=='CertificateArn'].OutputValue" --output text 2>$null
if (-not $CERT_ARN -or $CERT_ARN -eq "None") {
    Write-Warning "CertificateArn not found (Stack $CERT_STACK might be missing or failed)"
} else {
    Write-Host "CertificateArn: $CERT_ARN"
}

Write-Host "--------------------------------------------------------"
Write-Host "Use these values in your Application's configuration."
