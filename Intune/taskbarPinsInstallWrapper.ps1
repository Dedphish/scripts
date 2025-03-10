<#
.DESCRIPTION
    Install copies a packaged .xml file to $xmlSysPath, uninstall deletes it.

.EXAMPLE
    To deploy as Win32 use a detection-rule looking for the xmlFile at xmlSysPath directly in Intune.
    If you change the name of the XML file, make sure to adjust $xmlFile below, and in the detection rule
#>

#region Parameters
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("install", "uninstall")]
    [string]$action
)

$xmlSysPath = "$($env:USERPROFILE)\AppData\Local\Microsoft\Windows\Shell"
$xmlFile = "LayoutModification.xml" # This value must be used for the detection-rule in Intune

$runOnceRegKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce"

$myCustomRegPath = "HKCU:\Software\MyPath\Apps"
$appName = "TaskbarLayout"

$appRegPath = "$myCustomRegPath\$appName"
#endregion

#region Script
switch ($action) {
    "install" {
        # Copy layout XML to local system
        Copy-Item -Path "$PSScriptRoot\$xmlFile" -Destination $xmlSysPath
        Write-Host "Copied XML to destination $xmlSysPath" -ForegroundColor Green

        # Create RunOnce-key in registry to delete XML after next logon
        New-ItemProperty -Path $runOnceRegKey -Name "!DeleteTaskbarXml" -Value "cmd.exe /c del /f `"$xmlSysPath\$xmlFile`""

        # Set install-flag to detect installation
    
        if (!Test-Path -Path $appRegPath) {
            New-Item -Path $appRegPath -Force
        }

        exit 0
    }

    "uninstall" {
        # Delete install-flag
        if (Test-Path -Path $appRegPath) {
            Remove-Item -Path $appRegPath -Force
        }

        $fullXmlPath = "$xmlSysPath\$xmlFile"
        if (Test-Path -Path $fullXmlPath) {
            Remove-Item -Path $fullXmlPath -Force
            Write-Host "Deleted XML at path $xmlSysPath" -ForegroundColor Green
            exit 0
        }
        
        Write-Host "XML file not found, exiting..." -ForegroundColor Yellow
        exit 0
    }
}
#endregion
