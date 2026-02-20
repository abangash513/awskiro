# VPN Connectivity Diagnostic Script
# Run this with valid AWS credentials

$endpointId = "cvpn-endpoint-02fbfb0cd399c382c"
$region = "us-west-2"

Write-Host "=== VPN Connectivity Diagnostics ===" -ForegroundColor Green
Write-Host ""

# Check endpoint status
Write-Host "[1] VPN Endpoint Status..." -ForegroundColor Cyan
aws ec2 describe-client-vpn-endpoints --client-vpn-endpoint-ids $endpointId --region $region --query 'ClientVpnEndpoints[0].[ClientVpnEndpointId,Status.Code,VpcId]' --output table
Write-Host ""

# Check subnet associations
Write-Host "[2] Subnet Associations..." -ForegroundColor Cyan
aws ec2 describe-client-vpn-target-networks --client-vpn-endpoint-id $endpointId --region $region --query 'ClientVpnTargetNetworks[*].[AssociationId,TargetNetworkId,Status.Code]' --output table
Write-Host ""

# Check authorization rules
Write-Host "[3] Authorization Rules..." -ForegroundColor Cyan
aws ec2 describe-client-vpn-authorization-rules --client-vpn-endpoint-id $endpointId --region $region --query 'AuthorizationRules[*].[DestinationCidr,Status.Code,AccessAll]' --output table
Write-Host ""

# Check routes
Write-Host "[4] Route Table..." -ForegroundColor Cyan
aws ec2 describe-client-vpn-routes --client-vpn-endpoint-id $endpointId --region $region --query 'Routes[*].[DestinationCidr,TargetSubnet,Status.Code,Type]' --output table
Write-Host ""

# Check security groups on subnets
Write-Host "[5] Checking subnet security..." -ForegroundColor Cyan
$subnets = aws ec2 describe-client-vpn-target-networks --client-vpn-endpoint-id $endpointId --region $region --query 'ClientVpnTargetNetworks[*].TargetNetworkId' --output text

if ($subnets) {
    foreach ($subnet in $subnets -split '\s+') {
        Write-Host "  Subnet: $subnet" -ForegroundColor Yellow
        aws ec2 describe-subnets --subnet-ids $subnet --region $region --query 'Subnets[0].[SubnetId,CidrBlock,AvailabilityZone]' --output table
    }
}
Write-Host ""

Write-Host "=== Recommendations ===" -ForegroundColor Green
Write-Host ""
Write-Host "If subnet associations show 'associating':" -ForegroundColor Yellow
Write-Host "  - Wait 5-10 minutes for full propagation"
Write-Host "  - Disconnect and reconnect VPN"
Write-Host ""
Write-Host "If authorization rules are missing:" -ForegroundColor Yellow
Write-Host "  - Run: aws ec2 authorize-client-vpn-ingress --client-vpn-endpoint-id $endpointId --target-network-cidr 10.60.0.0/16 --authorize-all-groups --region $region"
Write-Host ""
Write-Host "If routes are missing:" -ForegroundColor Yellow
Write-Host "  - Run: aws ec2 create-client-vpn-route --client-vpn-endpoint-id $endpointId --destination-cidr-block 10.60.0.0/16 --target-vpc-subnet-id subnet-06888c11ff940086d --region $region"
Write-Host ""
