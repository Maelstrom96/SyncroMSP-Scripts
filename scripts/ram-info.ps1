<#
.Synopsis
  Retrieve RAM DIMM size, type and available slot

.DESCRIPTION

.SYNCRO-CUSTOM-FIELDS
  DIMM Type        | Text field
  DIMM Form Factor | Text field
  DIMM Table       | Text area

.NOTES
  Version:        1.0
  Author:         Alexandre-Jacques St-Jacques
  Creation Date:  23-09-2021
  Purpose/Change: Initial script development

.LINK 
  https://github.com/Maelstrom96/SyncroMSP-Scripts/blob/main/scripts/ram-info.ps1
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

function Get-DIMM-Count {
    return @(Get-WmiObject -class "win32_physicalmemory").Count
}

function Get-DIMM-Total {
    return ((Get-WmiObject -Class "win32_PhysicalMemoryArray" ).MemoryDevices | Measure-Object -Sum).Sum 
}

function Get-DIMM-Available {
    return (Get-DIMM-Total) - (Get-DIMM-Count)
}

function Get-DIMM-Type {
    Param(
        [Parameter(Mandatory=$true)]
        [Int] $id
    )

    $DIMMType = $null

    switch ($id)
    {
        20 {$DIMMType = "DDR"}
        21 {$DIMMType = "DDR2"}
        22 {$DIMMType = "DDR2 FB-DIMM"}
        24 {$DIMMType = "DDR3"}
        26 {$DIMMType = "DDR4"}
    }

    return $DIMMType
}

function Get-DIMM-Types {
    $DIMMTypeID = @(Get-WmiObject -class "win32_physicalmemory")[0].SMBIOSMemoryType

    return (Get-DIMM-Type -id $DIMMTypeID)
}

function Get-DIMM-FormFactor {
    Param(
        [Parameter(Mandatory=$true)]
        [Int] $id
    )
    
    $FormFactor = $null
    switch ($id)
    {
        0 {$FormFactor = "Unknown"}
        1 {$FormFactor = "Other"}
        2 {$FormFactor = "SIP"}
        3 {$FormFactor = "DIP"}
        4 {$FormFactor = "ZIP"}
        5 {$FormFactor = "SOJ"}
        6 {$FormFactor = "Proprietary"}
        7 {$FormFactor = "SIMM"}
        8 {$FormFactor = "DIMM"}
        9 {$FormFactor = "TSOP"}
        10 {$FormFactor = "PGA"}
        11 {$FormFactor = "RIMM"}
        12 {$FormFactor = "SODIMM"}
        13 {$FormFactor = "SRIMM"}
        14 {$FormFactor = "SMD"}
        15 {$FormFactor = "SSMP"}
        16 {$FormFactor = "QFP"}
        17 {$FormFactor = "TQFP"}
        18 {$FormFactor = "SOIC"}
        19 {$FormFactor = "LCC"}
        20 {$FormFactor = "PLCC"}
        21 {$FormFactor = "BGA"}
        22 {$FormFactor = "FPBGA"}
        23 {$FormFactor = "LGA"}
        24 {$FormFactor = "FB-DIMM"}
    }

    return $FormFactor
}

function Get-DIMM-FormFactors {
    $FormFactorIDList = @(Get-WmiObject -class "win32_physicalmemory") | Select-Object -Unique formfactor
    $FormFactorList = New-Object System.Collections.Generic.List[string]

    $FormFactorIDList | ForEach-Object {
        $FormFactorList.Add((Get-DIMM-FormFactor -id $_.formfactor))
    }

    return $FormFactorList -join ","
}

$PhysicalMemory = Get-WmiObject -class "win32_physicalmemory" 
$table = $PhysicalMemory | Format-Table BankLabel,@{n="Capacity(GB)";e={$_.Capacity/1GB}},Manufacturer,PartNumber,Speed,@{n="Form Factor";e={Get-DIMM-FormFactor -id $_.formfactor}},@{n="Memory Type";e={Get-DIMM-Type -id $_.SMBIOSMemoryType}} -AutoSize 
$table

Write-Host "Total DIMM Slots: $(Get-DIMM-Total)"
Write-Host "Used DIMM Slots: $(Get-DIMM-Count)"
Write-Host "Available DIMM Slots: $(Get-DIMM-Available)"

Set-Asset-Field -Name "DIMM Type" -Value (Get-DIMM-Types)
Set-Asset-Field -Name "DIMM Form Factor" -Value (Get-DIMM-FormFactors)
Set-Asset-Field -Name "DIMM Table" -Value ($table | Out-String)