<#Author       : Sebastian Di Cecca
# Usage        : Install Google Chrome and Adobe Reader DC
#>

#############################################
#         Install Google Chrome and Adobe Reader DC    #
#############################################

#region Set logging 
$logFile = "c:\ImageBuilder\" + (get-date -format 'yyyyMMdd') + '_softwareinstall.log'
function Write-Log {
    Param($message)
    Write-Output "$(get-date -format 'yyyyMMdd HH:mm:ss') $message" | Out-File -Encoding utf8 $logFile -Append
}
#endregion

# Inline command to download and extract AZCopy
New-Item -Type Directory -Path 'c:\' -Name 'ImageBuilder'
Invoke-Webrequest -uri 'https://aka.ms/downloadazcopy-v10-windows' -OutFile 'c:\ImageBuilder\azcopy.zip'
Expand-Archive 'c:\ImageBuilder\azcopy.zip' 'c:\ImageBuilder'
Copy-item 'C:\ImageBuilder\azcopy_windows_amd64_*\azcopy.exe\' -Destination 'c:\ImageBuilder'

#Check Azcopy unzip
$azcopyexe = 'C:\ImageBuilder\azcopy.exe'
    if (Test-Path $azcopyexe){
        Write-Log "AzCopy downloaded and unzipped successfully"    
    }
    else {
        Write-Log "AzCopy download and unzip failed"
    }

#Download exe and msi files from storage account
c:\ImageBuilder\azcopy.exe copy 'https://sttestweu01.blob.core.windows.net/aiblogs/*?sp=racwl&st=2023-10-24T07:36:16Z&se=2024-01-01T16:36:16Z&spr=https&sv=2022-11-02&sr=c&sig=rwIBp%2BAefHiC%2FNH4hz5r%2BF6DDWbmRORcGitwqS1mR90%3D' 'C:\Imagebuilder' --include-pattern '*.msi*;*.exe*'

#Set FilePaths
$ImageBuilderPath = 'C:\Imagebuilder'

#Region Google Chrome
# URL for the Google Chrome Enterprise MSI
$chromeMsiUrl = "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi"

# Destination path for the downloaded MSI file
$destinationFilePath = "$ImageBuilderPath\googlechromestandaloneenterprise64.msi"

# Download the MSI file
Invoke-WebRequest -Uri $chromeMsiUrl -OutFile $destinationFilePath

# Check if the download was successful
if (Test-Path $destinationFilePath) {
    Write-Log "Google Chrome Enterprise MSI downloaded successfully to $destinationFilePath"
    # Install Google Chrome
    try {
    Start-Process -Wait -FilePath "msiexec" -ArgumentList "/i `"$destinationFilePath`" /qn"
    # Check if Google Chrome is installed
        if (Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe") {
        Write-Log "Google Chrome is installed."
        } else {
        Write-Log "Error locating the Google Chrome executable"
        }
    }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Log "Google Chrome installation failed: $ErrorMessage"
    }
}
else {
    Write-Log "Failed to download Google Chrome Enterprise MSI."
    }

#EndRegion

#region Adobe Reader DC
try {
    Start-Process -filepath 'C:\ImageBuilder\AcroRdrDCx642300620360_MUI.exe' -Wait -ErrorAction Stop -ArgumentList '/sAll /rs /rps /msi EULA_ACCEPT=YES DISABLEDESKTOPSHORTCUT=1'
    if (Test-Path "C:\Program Files\Adobe\Acrobat DC\Acrobat\Acrobat.exe") {
        Write-Log "Acrobat Reader DC has been installed"
    }
    else {
        write-log "Error locating the Acrobat Reader DC executable"
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    write-log "Error installing Adobe Reader DC: $ErrorMessage"
}
#endregion



# Inline command that uses AZCopy to upload the log file for application installation to storage account
# Use the SAS URL for the <ArchiveSource>
c:\ImageBuilder\azcopy.exe copy $logFile 'https://sttestweu01.blob.core.windows.net/aiblogs?sp=racwl&st=2023-10-24T07:36:16Z&se=2024-01-01T16:36:16Z&spr=https&sv=2022-11-02&sr=c&sig=rwIBp%2BAefHiC%2FNH4hz5r%2BF6DDWbmRORcGitwqS1mR90%3D'

#CleanUp Region
#Remove Imagebuilder folder
Remove-Item -Path 'C:\Imagebuilder' -Recurse -Force
#EndRegion
