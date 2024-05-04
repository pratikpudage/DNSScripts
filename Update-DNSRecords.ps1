<# Version 1.1 - Modified
Author: pratikpudage80@gmail.com
GitHub: https://github.com/pratikpudage/PowerShell

Note: Input CSV File must contain columns, AzureHostName, AzureIP, OnPremHostName, and OnPremIP

Summary: Custom PowerShell function Update-DNSRecords in this script is purpose built to perform the following steps in order -
1. From the established mapping in the input csv file, delete the A record listed under OnPremHostName. This also removes corresponding PTR record for the host if it exists.
2. Create a CNAME record to replace the deleted A record from step 1 above, the CNAME record is mapped to the AzureHostName provided in the input file.

Usage example: Update-DNSRecords -CsvFilePath .\PathtoCsvFile.csv -DNSZone "your.dns.zone"
#>

function Update-DNSRecords {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CsvFilePath,

        [Parameter(Mandatory = $true)]
        [string]$DNSZone
    )

    # Initialize counters for summary
    $ARecordsDeletedSuccessfully = 0
    $ARecordsFailedToDelete = 0
    $CNAMERecordsCreatedSuccessfully = 0
    $CNAMERecordsFailedToCreate = 0

    # Logging
    $LogFilePath = "DNSUpdateLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    $CNameRecordsCreationLog = "CNAMERecords_Creation_$(Get-Date -Format 'yyyyMMdd_HH').csv"
    $ARecordsDeletionLog = "ARecord_Deletions_$(Get-Date -Format 'yyyyMMdd_HH').csv"
    Start-Transcript -Path $LogFilePath

    try {
        # Read CSV file
        $CSVData = Import-Csv -Path $CsvFilePath

        # Process each row
        foreach ($row in $CSVData) {
            $OnPremHostName = $row.OnPremHostName
            $AzureHostName = $row.AzureHostName
            $OnPremIPAddress = $row.OnPremIP

            # Remove A record
            try {
                Remove-DnsServerResourceRecord -ZoneName $DNSZone -Name $OnPremHostName -RRType "A" -RecordData $OnPremIPAddress -Force -ErrorAction Stop
                Write-Host "Successfully deleted A record for $OnPremHostName" -ForegroundColor Blue
                $ARecordsDeletedSuccessfully++
                $row | Select-Object OnPremHostName,OnPremIP | Export-Csv -Append -Path $ARecordsDeletionLog -NoTypeInformation
            }
            catch {
                # Write-Host "Failed to delete A record for $OnPremHostName" -ForegroundColor Red
                $ARecordsFailedToDelete++
            }

            # Create CNAME record
            try {
                Add-DnsServerResourceRecordCName -ZoneName $DNSZone -Name $OnPremHostName -HostNameAlias "$AzureHostName.$DNSZone" -ErrorAction Stop
                Write-Host "Successfully created CNAME record for $OnPremHostName" -ForegroundColor Green
                $CNAMERecordsCreatedSuccessfully++
                $row | Select-Object OnPremHostName,AzureHostName | Export-Csv -Append -Path $CNameRecordsCreationLog -NoTypeInformation
            }
            catch {
                # Write-Host "Failed to create CNAME record for $OnPremHostName" -ForegroundColor Red
                $CNAMERecordsFailedToCreate++
            }
        }
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
    finally {
        Stop-Transcript

        # Summary
        Write-Host "###### Process Summary ######" -ForegroundColor Blue
        Write-Host "A records successfully deleted - $ARecordsDeletedSuccessfully" -ForegroundColor Green
        Write-Host "A records failed to delete - $ARecordsFailedToDelete" -ForegroundColor Red
        Write-Host "CNAME records successfully created - $CNAMERecordsCreatedSuccessfully" -ForegroundColor Green
        Write-Host "CNAME records failed to create - $CNAMERecordsFailedToCreate" -ForegroundColor Red
        Write-Host "Execution Transcript saved at - $LogFilePath" -ForegroundColor Yellow
        Write-Host "All CNAME records created saved at - $CNameRecordsCreationLog" -ForegroundColor Yellow
        Write-Host "All A records deletions saved at - $ARecordsDeletionLog" -ForegroundColor Yellow      
    }
}