<# Version 1.0 - Final
Author: pratikpudage80@gmail.com
GitHub: https://github.com/pratikpudage/PowerShell

Note: Input CSV File must contain two columns, viz. Hostname and RecordData

Summary: Custom PowerShell function Remove-DNSRecords in this script is purpose built to delete DNS A or CNAME records and corresponding PTR records wherever applicable for hosts provided under the input CSV file.

Usage example: Remove-DNSRecords -CsvPath .\PathtoCsvFile.csv -DNSZone "your.dns.zone" -RecordType "A"
               Remove-DNSRecords -CsvPath .\PathtoCsvFile.csv -DNSZone "your.dns.zone" -RecordType "CNAME"
#>

function Remove-DNSRecords {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType 'Leaf'})]
        [string]$CsvPath,
        
        [Parameter(Mandatory = $true)]
        [string]$DNSZone,

        [Parameter(Mandatory = $true)]
        [ValidateSet("A", "CNAME")]
        [string]$RecordType
    )

    begin {
        $LogPath = "C:\DNSRecordRemovalLog_$(Get-Date -Format 'yyyyMMdd_HHmm').txt"
        $ReportPath = "C:\DNSRecordRemovalReport_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
        $FailedRecords = @()
        $SuccessfulRecords = @()
    }

    process {
        Import-Csv $CsvPath | ForEach-Object {
            $Hostname = $_.Hostname
            $RecordData = $_.RecordData

            try {
                if ($RecordType -eq "A") {
                    # Remove A Record
                    Remove-DnsServerResourceRecord -Name $Hostname -ZoneName $DNSZone -RRType "A" -RecordData $RecordData -Force -ErrorAction Stop
                }
                elseif ($RecordType -eq "CNAME") {
                    # Remove CNAME Record
                    Remove-DnsServerResourceRecord -Name $Hostname -ZoneName $DNSZone -RRType "CNAME" -RecordData $RecordData -Force -ErrorAction Stop
                }

                $SuccessfulRecords += [PSCustomObject]@{
                    Hostname = $Hostname
                    RecordData = $RecordData
                    RecordType = $RecordType
                    RemoveStatus = "Success"
                }                
            }
            catch {
                $FailedRecords += [PSCustomObject]@{
                    Hostname = $Hostname
                    RecordData = $RecordData
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
        
        # Summary
        Write-Host "###### Process Summary ######" -ForegroundColor Blue
        Write-Host "Successful Records Removal: $($SuccessfulRecords.Count)" -ForegroundColor Green
        Write-Host "Failed Records Removal: $($FailedRecords.Count)" -ForegroundColor Red
        Write-Host "Detailed report saved at: $ReportPath" -ForegroundColor Yellow
        Write-Host "Log saved at: $LogPath" -ForegroundColor Yellow
    }
}