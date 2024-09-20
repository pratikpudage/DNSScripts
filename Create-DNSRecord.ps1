function Create-DNSRecord {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Hostname,

        [Parameter(Mandatory=$true)]
        [string]$IPAddress,

        [Parameter(Mandatory=$true)]
        [string[]]$DNSServers,

        [Parameter(Mandatory=$true)]
        [string[]]$Zones
    )

    foreach ($Zone in $Zones) {
        foreach ($DNSServer in $DNSServers) {
            $ARecordExists = $false
            $PTRRecordExists = $false

            # Resolve A record using Resolve-DnsName
            try {
                $ARecord = Resolve-DnsName -Name $Hostname -Server $DNSServer -Type A -ErrorAction Stop
                if ($ARecord) {
                    Write-Host "A record for $Hostname already exists in zone $Zone on DNS server $DNSServer"
                    Write-Host "Record Details:"
                    $ARecord | Format-Table -AutoSize
                    $ARecordExists = $true
                }
            } catch {
                Write-Host "No A record for $Hostname found in zone $Zone on DNS server $DNSServer"
            }

            # Reverse the IP address for PTR record
            #$IPAddressParts = $IPAddress.Split('.')
            #$ReversedIP = "$($IPAddressParts[3]).$($IPAddressParts[2]).$($IPAddressParts[1]).$($IPAddressParts[0]).in-addr.arpa"
            
            # Resolve PTR record using Resolve-DnsName
            try {
                $PTRRecord = Resolve-DnsName -Name $IPAddress -ErrorAction Stop
                if ($PTRRecord) {
                    Write-Host "PTR record for $IPAddress already exists on DNS server $DNSServer"
                    Write-Host "Record Details:"
                    $PTRRecord.NameHost | Format-Table -AutoSize
                    $PTRRecordExists = $true
                }
            } catch {
                Write-Host "No PTR record for $IPAddress found on DNS server $DNSServer"
            }

            # Create A record if it doesn't exist
            if ((-not $ARecordExists) -and (-not $PTRRecordExists)) {
                Write-Host "Creating A record..."
                Add-DnsServerResourceRecordA -Name $Hostname -ZoneName $Zone -IPv4Address $IPAddress -ComputerName $DNSServer -CreatePtr
                Write-Host "A record for $Hostname created in zone $Zone on DNS server $DNSServer"
            }
        }
    }
}

# Create-DNSRecord -Hostname client01 -IPAddress 10.0.1.3 -DNSServers adds-ppudage -Zones @("testdomain.net", "fremont.lamrc.net")
