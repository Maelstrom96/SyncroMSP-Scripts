<#
.Synopsis
  Retrieve the bitlocker recovery key for each volume & status
.DESCRIPTION

.SYNCRO-VARS
  # Save the result into a custom asset field
  save | Dropdown | "True", "False"

.SYNCRO-CUSTOM-FIELDS
  BitLocker Backup Key    | Text area
  BitLocker Volume Status | Text area

.NOTES
  Version:        1.0
  Author:         Alexandre-Jacques St-Jacques
  Creation Date:  15-05-2021
  Purpose/Change: Initial script development

.LINK 
  https://github.com/Maelstrom96/SyncroMSP-Scripts/blob/main/scripts/bitlocker-recoverykey-status.ps1
#>

try {
    Import-Module $env:SyncroModule -erroraction stop 
}
catch {
    $env:RepairTechUUID = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\RepairTech\Syncro" -Name "uuid").uuid
    $env:RepairTechApiBaseURL = "syncromsp.com"
    $env:RepairTechApiSubDomain = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\RepairTech\Syncro" -Name "shop_subdomain").shop_subdomain
    $env:RepairTechFilePusherPath = "$($env:PROGRAMDATA)\Syncro\bin\FilePusher.exe"

    Import-Module "$($env:PROGRAMDATA)\Syncro\bin\module.psm1" 3>$null
}

function Get-Bitlocker-RecoveryPasswords {
    param(
        [Parameter(Mandatory=$true)]
        [Boolean] $SaveToSyncro,
        [Parameter(Mandatory=$false)]
        [Boolean] $ReportOnlyBitlockerEnabledVolumeStatus = $True,
        [Parameter(Mandatory=$false)]
        [String] $BackupKeyFieldName = "BitLocker Backup Key",
        [Parameter(Mandatory=$false)]
        [String] $VolumeStatusFieldName = "BitLocker Volume Status"
    )
    
    $RecoveryPasswords = ""
    $VolumeStatus = ""
    
    # Identify all the Bitlocker volumes.
    $BitlockerVolumes = Get-BitLockerVolume
    
    # For each volume, get the RecoveryPassword and display it.
    $BitlockerVolumes |
        ForEach-Object {
            $MountPoint = $_.MountPoint
            $status = $_.VolumeStatus
            $RecoveryKey = [string]($_.KeyProtector).RecoveryPassword
            if ($RecoveryKey.Length -gt 5) {
                Write-Host ("The drive $MountPoint has a recovery key $RecoveryKey.")
                $RecoveryPasswords += "$MountPoint/ > $RecoveryKey"
                $RecoveryPasswords += "`r`n"
            }
            if (!$ReportOnlyBitlockerEnabledVolumeStatus -or ($RecoveryKey.Length -gt 5)) {
                Write-Host ("The drive $MountPoint status is: $status.")
                $VolumeStatus += "$MountPoint/ > $status"
                $VolumeStatus += "`r`n"
            }
        }
        
    if ($saveToSyncro -eq $true) {
        Set-Asset-Field -Name $BackupKeyFieldName -Value $RecoveryPasswords
        Set-Asset-Field -Name $VolumeStatusFieldName -Value $VolumeStatus
    }
}

$saveBool = [System.Convert]::ToBoolean($save)

Get-Bitlocker-RecoveryPasswords -SaveToSyncro $saveBool