<#
.Synopsis
   Check TPM Version, SecureUEFI and BootType
.DESCRIPTION

.SYNCRO-VARS
# If the TPM check fails, exit the script with an error.
FailOnMissing | Dropdown | "True", "False"

.SYNCRO-CUSTOM-FIELDS
TPM              | Text field
TPM Enabled      | Check box
Secure Boot UEFI | Check box
BootType         | Text field

.NOTES
  Version:        1.0
  Author:         Alexandre-Jacques St-Jacques
  Creation Date:  15-05-2021
  Purpose/Change: Initial script development
#>

#Param (
#    [parameter(Mandatory=$false)]
#    $localdebug = 'False',
#    [parameter(Mandatory=$false)]
#    $FailOnMissing = 'False'
#)

if (![System.Convert]::ToBoolean($localdebug)) {
    Import-Module $env:SyncroModule
}
else {
    $env:RepairTechUUID = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\RepairTech\Syncro" -Name "uuid").uuid
    $env:RepairTechApiBaseURL = "syncromsp.com"
    $env:RepairTechApiSubDomain = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\RepairTech\Syncro" -Name "shop_subdomain").shop_subdomain
    $env:RepairTechFilePusherPath = "$($env:PROGRAMDATA)\Syncro\bin\FilePusher.exe"

    Import-Module "$($env:PROGRAMDATA)\Syncro\bin\module.psm1" 3>$null
}

# Outputs
$BOOTTYPE = "N/A"
$TPM = "N/A"
$TPMEnabled = $False
$UEFI = $False

$tpmobj = Get-Tpm

# Print TPM in logs
$tpmobj

if ($tpmobj.TpmPresent){
    if([string]::IsNullOrEmpty($tpmobj.TpmEnabled)) {
        $value = (wmic /namespace:\\root\cimv2\security\microsofttpm path win32_tpm get IsEnabled_InitialValue | findstr /v IsEnabled_InitialValue)
        $value = [string]::join("",($value.Split("`n"))) # Remove the fluf arround the value
        $value = $value.Trim()
        Write-Host $value
        if ($value -eq "TRUE") {$TPMEnabled = $True}
        if ($value -eq "FALSE") {$TPMEnabled = $False}
    }
    else {
        if($tpmobj.TpmEnabled) {
        	$TPMEnabled = $True
    	}
        else {
        	$TPMEnabled = $False
        }
    }

	$TPM = (wmic /namespace:\\root\CIMV2\Security\MicrosoftTpm path Win32_Tpm get SpecVersion | findstr /v SpecVersion)
    $TPM  = [string]::join("",($TPM.Split("`n"))) # Remove the fluf arround the value
    $TPM = $TPM -replace '\s',''
}
else {
	$TPM = "NotPresent"
}

$BOOTTYPE = $env:firmware_type
$SecureUEFI = Confirm-SecureBootUEFI

Write-Host "TPM Version:" $TPM
Write-Host "TPM Enabled:" $TPMEnabled
Write-Host "Boot type:" $BOOTTYPE
Write-Host "Secure Boot UEFI:" $SecureUEFI

Set-Asset-Field -Name "TPM" -Value $TPM
Set-Asset-Field -Name "TPM Enabled" -Value $(if($TPMEnabled) {1} else {0})
Set-Asset-Field -Name "Secure Boot UEFI" -Value $(if($SecureUEFI) {1} else {0})
Set-Asset-Field -Name "BootType" -Value $BOOTTYPE

$FailOnMissingBool = [System.Convert]::ToBoolean($FailOnMissing)
if ($FailOnMissingBool -and !$tpmobj.TpmPresent) {
	exit 1
}