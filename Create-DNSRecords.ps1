<# Version 1.0 - Final
Author: pratikpudage80@gmail.com
GitHub: https://github.com/pratikpudage/PowerShell

Note: Input CSV File must contain two columns, viz. Hostname and IPAddress

Summary: Custom PowerShell function New-DNSRecords in this script is purpose built to create DNS A records and corresponding PTR records for hosts provided udner the input CSV file.

Usage example: New-DNSRecords -CsvPath .\PathtoCsvFile.csv -DNSZone "your.dns.zone"
#>


function New-DNSRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [string]$CsvPath,
        
        [Parameter(Mandatory = $true)]
        [string]$DNSZone
    )

    begin {
        $LogPath = "C:\DNSRecordCreationLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $ReportPath = "C:\DNSRecordCreationReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $FailedRecords = @()
        $SuccessfulRecords = @()
    }

    process {
        Import-Csv $CsvPath | ForEach-Object {
            $Hostname = $_.Hostname
            $IPAddress = $_.IPAddress

            try {
                # Create A Record
                Add-DnsServerResourceRecordA -Name $Hostname -ZoneName $DNSZone -IPv4Address $IPAddress -CreatePtr -ErrorAction Stop
                Write-Host "Successfully created A record for $HostName" -ForegroundColor Green
                $SuccessfulRecords += [PSCustomObject]@{
                    Hostname = $Hostname
                    IPAddress = $IPAddress
                    RecordType = "A"
                    CreationStatus = "Success"
                }                
            }
            catch {
                $FailedRecords += [PSCustomObject]@{
                    Hostname = $Hostname
                    IPAddress = $IPAddress
                    Error = $_.Exception.Message
                }
            }
        }
    }

    end {
        $SuccessfulRecords | Export-Csv -Path $ReportPath -NoTypeInformation -Append
        $FailedRecords | Export-Csv -Path $ReportPath -NoTypeInformation -Append
        
        # Log all changes
        $SuccessfulRecords | Out-File -FilePath $LogPath -Append
        $FailedRecords | Out-File -FilePath $LogPath -Append
        
        # Display Summary
        Write-Host "DNS Record Creation Summary:" -ForegroundColor Blue
        Write-Host "Successful Records: $($SuccessfulRecords.Count)" -ForegroundColor Green
        Write-Host "Failed Records: $($FailedRecords.Count)" -ForegroundColor Red
        Write-Host "Detailed report saved at: $ReportPath" -ForegroundColor Yellow
        Write-Host "Log saved at: $LogPath" -ForegroundColor Yellow
    }
}