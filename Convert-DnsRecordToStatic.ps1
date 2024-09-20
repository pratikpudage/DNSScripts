function Convert-DnsRecordToStatic {
    param (
        [Parameter(Mandatory=$true)]
        [string]$RecordName,

        [Parameter(Mandatory=$true)]
        [string]$ZoneName
    )

    # Get DNS record
    $dnsRecord = Get-DnsServerResourceRecord -Name $RecordName -ZoneName $ZoneName -ErrorAction SilentlyContinue
    

    if (-not $dnsRecord)  {
        Write-Host "DNS record '$RecordName' not found in zone '$ZoneName'." -ForegroundColor Red
        $Result = "RecordNotFound"
        $Result
        return
    }

    # Check if the record is dynamic
    if ($dnsRecord.RecordType -eq 'A' -and $dnsRecord.Timestamp -gt 0) {
        Write-Host "The DNS record '$RecordName' is dynamic. Converting to static..."
        
        # Remove the dynamic record
        Remove-DnsServerResourceRecord -ZoneName "$ZoneName" -Name "$RecordName" -RRType "A" -Force

        # Add a new static DNS record with the same data
        Add-DnsServerResourceRecordA -Name $RecordName -ZoneName $ZoneName -IPv4Address $dnsRecord.RecordData.IPv4Address.IPAddressToString -CreatePtr

        $Result = "ConvertedToStatic"

        Write-Host "DNS record '$RecordName' has been converted to static." -ForegroundColor Green
    } else {
        $Result = "RecordAlreadyStatic"
        Write-Host "The DNS record '$RecordName' is already static. No changes made." -ForegroundColor Yellow
    }
    $Result
}

# Usage
# . .\Convert-DnsRecordToStatic.ps1
# Convert-DnsRecordToStatic -RecordName TestClient -ZoneName testdomain.net