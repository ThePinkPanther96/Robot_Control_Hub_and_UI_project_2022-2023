# Get Path
$scriptDirectory = Split-Path $MyInvocation.MyCommand.Path
# Set working directory to the script directory
Set-Location $scriptDirectory
$BackupsPath = "D:\Backup_Files"
$SiteVarsPath = "D:\Site Variables"

# Error message
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$MsgBoxError = [System.Windows.Forms.MessageBox]

# Logger i
Function Logger()
{
 param
    (
    [Parameter(Mandatory=$true)] [string] $Message
    )
    Try {
        $LogFile = "C:\X_UI\Logs\Control_Hub_Event_log.log" #To Edit
        $TimeStamp = (Get-Date).toString("dd/MM/yyyy HH:mm:ss:fff tt")
        $Line = "$TimeStamp - $Message"
        Add-content -Path $Logfile -Value $Line
 
        Write-host "Message: '$Message' Has been Logged to File: $LogFile"
    }
    Catch {
        Write-host -f Red "Error:" $_.Exception.Message
    }
}

# To Test
function UserReg() {
    param (
        [string]$Username
    )
    try {
        if ($Username) {
            reg load HKU\$Username C:\users\$Username\NTUSER.DAT
            Logger [string]::Concat( "[message][UserReg] - HKU\$Username C:\users\$Username\NTUSER.DAT Loaded Successfully")
        }
        else {
            Logger "[ALERT][UserReg] - Missing Imput. Function Stoped."
        }
    }
    catch [System.SystemException] {
        Logger "[ERROR][UserReg] - System Error: $_"
    }
}

# To Test
function UserRegConfig() {
    param (
        [int]$TimeOut,
        [string]$Username
    )
    try {
        if (UserReg -and $TimeOut -as [int]) {

            $content1 = @('Windows Registry Editor Version 5.00
            ')
            $content2 = [string]::Concat("[HKEY_USERS\",$Username,"\Control Panel\Desktop]")
            $content3 = @('"ScreenSaveActive"="1"')
            $content4 = [string]::Concat('"ScreenSaveTimeOut"',"=",'"',$TimeOut,'"')
            $content5 = @('"ScreenSaverIsSecure"="1"')

            Set-Content -Path 'C:\Windows\Temp\ScreenTimeoutRegistry.reg' `
                -Value $content1`n$content2`n$content3`n$content4`n$content5
            Logger "[MESSAGE][UserRegConfig] - C:\Windows\Temp\ScreenTimeoutRegistry.reg Deployed Successfully"   
        }
        else {
            Logger "[MESSAGE][UserRegConfig] - Missing Imput. Function Stoped."
            return;
        }
    }
    catch [System.SystemException] {
        Logger "[ERROR][UserRegConfig] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator.", $mailtaitel, "OK", "Error")
    } 

}

# To Test
function RunReg {
    try {
        if (UserReg -and UserRegConfig) {
            Start-Process -filepath "$env:windir\regedit.exe" -Argumentlist @("/s", "`"C:\Windows\Temp\ScreenTimeoutRegistry.reg`"")
            Logger "[MESSAGE][RunReg] - ScreenTimeoutRegistry.reg Key Deployed Successfully"
        }
        else {
            Logger "[ERROR][UserRegConfig] - Missing Imput. Function Stoped."
            return;
        }
    }
    catch [System.SystemException] {
        Logger "[MESSAGE][RunReg] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator.", $mailtaitel, "OK", "Error")
    }
}

# In Use
function BitLockerOn_C {
    try {
        Enable-Bitlocker -MountPoint "C:" -SkipHardwareTest -RecoveryPasswordProtector
        Resume-BitLocker -MountPoint "C"
        
        Logger "[MESSAGE][BitLockerOn_C] - BitLocker (C: Drive) Turned on." 
    }
    catch [System.SystemException] {
        Logger "[ERROR][BitLockerOn_C] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator.", $mailtaitel, "OK", "Error")
        return;
    }
}

# In Use - to edit
function BitLockerOn_D {
    try {
        Enable-Bitlocker -MountPoint "D:" -SkipHardwareTest -RecoveryPasswordProtector
        Resume-BitLocker -MountPoint "D"
        Logger "[MESSAGE][BitLockerOn_D] - D: Drive was sucessfuly Auto Unlocked" 
        
        Get-BitLockerVolume | ? {$_.VolumeType -eq 'Data'} | Enable-BitLockerAutoUnlock
        Logger "[MESSAGE][BitLockerOn_D] - BitLocker (D: Drive) Turned on." 
    }
    catch [System.SystemException] {
        Logger "[ERROR][BitLockerOn_D] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator.", $mailtaitel, "OK", "Error") 
    }
}

# In Use - to edit
function BitLockerOff {
    try {
        Clear-BitLockerAutoUnlock 
        Get-BitLockerVolume | Disable-BitLocker
        Logger "[MESSAGE][BitLockerOff] - BitLocker Turned off."
    }
    catch [System.SystemException] {
        Logger "[ERROR][BitLockerOff] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator.", $mailtaitel, "OK", "Error")
    }
}

# In Use - to edit
function BitLockerRecovry {
    try {
        (Get-BitLockerVolume -MountPoint "C").KeyProtector.recoverypassword > "$BackupsPath\C_BitLocker_Recovery_key.txt"
        (Get-BitLockerVolume -MountPoint "D").KeyProtector.recoverypassword > "$BackupsPath\D_BitLocker_Recovery_key.txt"

        Logger "[MESSAGE][BitLockerRecovry] - BitLocker Recovery Key updated."
    }
    catch [System.SystemException]  {
        Logger "[ERROR][BitLockerRecovry] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator.", $mailtaitel, "OK", "Error")  
    }
}

# In Use
function NetworkBackup {
    try {
        cmd /c "netsh -c interface dump > $BackupsPath\NetConfig.txt"
        Logger "[MESSAGE][NetworkBackup] - Network Settings backed up Successfully to $BackupsPath\NetConfig.txt."
    }
    catch [System.SystemException] {
        Logger "[ERROR][NetworkBackup] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator.", $mailtaitel, "OK", "Error")
    }
}

# In Use
function NetworkRestore {
    try {
        cmd /c "netsh -f $BackupsPath\NetConfig.txt"
        Logger "[MESSAGE][NetworkRestore] - Network Settings restored Successfully."
    }
    catch [System.SystemException] {
        Logger "[ERROR][NetworkRestore] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator.", $mailtaitel, "OK", "Error")
    }
}

# In Use
function EncryptString {
    param (
        [string]$Password
    )
    $encryptedPassword = $Password | ConvertTo-SecureString -AsPlainText -Force
    $encryptedString = ConvertFrom-SecureString -SecureString $encryptedPassword
    $encryptedString
    Logger "[Message][EncryptString] - Password Encrypted successfully"
}

# In Use
function DecryptString {
    param (
        [string]$Password
    )
    $decryptedPassword = $matchedRow.Password | ConvertTo-SecureString
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($decryptedPassword))
    $plainPassword
    Logger "[Message][DecryptString] - Password Decrypted successfully"
}

# In Use
function AddDataToCSV {
    param (
        [string]$Username,
        [string]$Password,
        [string]$FullName
    )

    try {
        $file = "$SiteVarsPath\etc\credentials.csv"
        if (!(Test-Path -Path $file)) {
            "Username,Password,FullName" | Out-File -FilePath $file
            Logger "[MESSAGE][AddDataToCSV] - No CSV file was found. A new file was created in $file"
        }
        else {
            $fileContent = Get-Content -Path $file -Raw
            if ([string]::IsNullOrWhiteSpace($fileContent) -or $fileContent -eq "Username,Password,FullName") {
                "`n" | Out-File -Append -FilePath $file
            }
        }
        $existingData = Import-Csv -Path $file
        $existingArray = @($existingData) 
        $userExists = $existingArray | Where-Object { $_.Username -eq $Username }
        if (!$userExists) {
            $encryptedString = EncryptString -Password $Password
            $newData = @{
                Username = $Username
                Password = $encryptedString
                FullName = $FullName
            }
            $newObject = New-Object -TypeName pscustomobject -Property $newData
            $existingArray += $newObject
            $existingArray | Export-Csv -Path $file -NoTypeInformation

            Logger "[MESSAGE][AddDataToCSV] - Username $Username was added to the users DataBase"
            $MsgBoxError::Show("$FullName was created successfully!",$maintaitel, "OK", "Asterisk")
        } 
        else {
            Logger "[MESSAGE][AddDataToCSV] - Username $Username already exists. Function was not executed."
        }
    }
    catch {
        Logger "[ERROR][AddDataToCSV] - System Error: $_"
        $MsgBoxError::Show("Databse Error! Contact your System Administrator.", $mailtaitel, "OK", "Error")
    }
}

# In Use (?)
function RemoveDataFromCSV {
    Param (
        [string]$UsernameToRemove
    )
    try {
        $CsvPath = "$SiteVarsPath\etc\credentials.csv"
        $credData = Import-Csv $CsvPath
        $credDataFiltered = $credData | Where-Object { $_.Username -ne $UsernameToRemove }

        if ($credDataFiltered.Count -lt $credData.Count) {
            
            $credDataFiltered | Export-Csv $CsvPath -NoTypeInformation
            
            Logger "[MESSAGE][RemoveDataFromCSV] - Successfully removed $UsernameToRemove from the CSV file."
            $MsgBoxError::Show($UsernameToRemove + " Was Deleted successfully!",$maintaitel, "OK", "Asterisk")
        } 
        else {
            Logger "[MESSAGE][RemoveDataFromCSV] - Unable to find $UsernameToRemove in the CSV file. Job was not exceuted."
            $MsgBoxError::Show($UsernameToRemove + " Was not found!",$maintaitel, "OK", "Warning")
        }
    }
    catch {
        Logger "[ERROR][RemoveDataFromCSV] - System Error: $_"
        $MsgBoxError::Show("Database Error! Contact your System Administrator.", $mailtaitel, "OK", "Error") 
    }
}

# In Use
function UpdateXML {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Node,
        [Parameter(Mandatory = $false)]
        [string]$NodeContent,
        [Parameter(Mandatory = $false)]
        [string]$FilePath
    )
    if (!(Test-Path -Path $FilePath)) {
        Logger "[ERROR][UpdateXML] - File path not found: $FilePath"
        $MsgBoxError::Show("Database Error! Could not connect to database.", $mailtaitel, "OK", "Error")
        return;
    }
    elseif (!($Node -and $NodeContent)) {
        return;
    }
    else {
        try {
            $xmlContent = Get-Content -Path $FilePath -Raw
            $xmlDoc = [System.Xml.XmlDocument]::new()
            $xmlDoc.PreserveWhitespace = $true
            $xmlDoc.LoadXml($xmlContent)
            Logger "[MESSAGE][UpdateXML] - Connected successfully to $FilePath"

            $targetNode = $xmlDoc.SelectSingleNode("//$Node")
            if ($targetNode) {

                if ([string]::IsNullOrEmpty($targetNode.InnerText)) {
                    $targetNode.InnerText = $NodeContent
                }
                else {
                    $targetNode.InnerText += ",$NodeContent"
                }
                $settings = New-Object System.Xml.XmlWriterSettings
                $settings.Indent = $true
                $settings.NewLineOnAttributes = $false
                $settings.Encoding = [System.Text.Encoding]::UTF8
    
                $stringWriter = New-Object System.IO.StringWriter
                $xmlWriter = [System.Xml.XmlWriter]::Create($stringWriter, $settings)
                $xmlDoc.WriteTo($xmlWriter)
                $xmlWriter.Flush()
                $xmlString = $stringWriter.ToString()
    
                $xmlString | Set-Content -Path $FilePath -Encoding UTF8
                Logger "[MESSAGE][UpdateXML] - Node: $Node was successfully updtated with the following values: $NodeContent"
            }
            else {
                Logger "[ERROR][UpdateXML] - Could not find requested node: $Node in database $FilePath"
                $MsgBoxError::Show("Database Error! Could not path in database.", $mailtaitel, "OK", "Error") 
            }
        }
        catch {
            Logger "[ERROR][UpdateXML] - System Error: $_"
            $MsgBoxError::Show("Database Error! Could not connect to database.", $mailtaitel, "OK", "Error") 
        }  
    } 
    
}

# In Use
function OverwriteXML {
    param(
        [Parameter(Mandatory = $false)]
        [string]$Node,
        [Parameter(Mandatory = $false)]
        [string]$NodeContent,
        [Parameter(Mandatory = $false)]
        [string]$FilePath
    )
    if (!(Test-Path -Path $FilePath)) {
        Logger "[ERROR][OverwriteXML] - Database path not found: $FilePath"
        $MsgBoxError::Show("Database Error! Could not connect to database.", $mailtaitel, "OK", "Error")
        return;
    }
    elseif (!($Node -and $NodeContent)) {
        Write-Host "Pass" -ForegroundColor "Blue"
        return;
    }
    else {
        try {
            $xmlContent = Get-Content -Path $FilePath -Raw
            $xmlDoc = [System.Xml.XmlDocument]::new()
            $xmlDoc.PreserveWhitespace = $true
            $xmlDoc.LoadXml($xmlContent)
            Logger "[MESSAGE][OverwriteXML] - Connected successfully to $FilePath"
    
            $targetNode = $xmlDoc.SelectSingleNode("//$Node")
            if ($targetNode) {
                $targetNode.InnerText = $NodeContent
                $settings = New-Object System.Xml.XmlWriterSettings
                $settings.Indent = $true
                $settings.NewLineOnAttributes = $false
                $settings.Encoding = [System.Text.Encoding]::UTF8
    
                $stringWriter = New-Object System.IO.StringWriter
                $xmlWriter = [System.Xml.XmlWriter]::Create($stringWriter, $settings)
                $xmlDoc.WriteTo($xmlWriter)
                $xmlWriter.Flush()
                $xmlString = $stringWriter.ToString()
                $xmlString | Set-Content -Path $FilePath -Encoding UTF8
                Logger "[MESSAGE][OverwriteXML] - Node: $Node was successfully updtated with the following values: $NodeContent"
            }
            else {
                Logger "[ERROR][OverwriteXML] - Could not find requested node: $Node in database $FilePath"
                $MsgBoxError::Show("Database Error! Could not path in database.", $mailtaitel, "OK", "Error") 
            }
        }
        catch {
            Logger "[ERROR][OverwriteXML] - System Error: $_"
            $MsgBoxError::Show("Database Error! Could not connect to database.", $mailtaitel, "OK", "Error") 
        } 
    }
}

# In Use
function CopyFile {
    param(
        [string]$DestinationPath,
        [string]$SourcePath,
        [string]$NewName
    )
    try {
        $extension = [System.IO.Path]::GetExtension($SourcePath)
        $destinationFile = Join-Path -Path $DestinationPath -ChildPath "$NewName$extension"
        Copy-Item -Path $SourcePath -Destination $destinationFile -Force
    }
    catch {
        Logger "[ERROR][CopyFile] - Could not copy file: $SourcePath to destination path: $DestinationPath"
        Logger "[ERROR][CopyFile] - System Error: $_"
        $MsgBoxError::Show("Could not generate new file.", $mailtaitel, "OK", "Error")
    }  
}

# To Fix
function ChangeDisplayTime {
    try {
        if ($DisplayTimeMenu.Text -eq "30"){
            powercfg -change -monitor-timeout-dc 30
            powercfg -change -monitor-timeout-ac 30
        }
        elseif ($DisplayTimeMenu.Text -eq "60") {
            powercfg -change -monitor-timeout-dc 60
            powercfg -change -monitor-timeout-ac 60 
        }
        elseif ($DisplayTimeMenu.Text -eq "90") {
            powercfg -change -monitor-timeout-dc 90
            powercfg -change -monitor-timeout-ac 90 
        }
        elseif ($DisplayTimeMenu.Text -eq "120") {
            powercfg -change -monitor-timeout-dc 120
            powercfg -change -monitor-timeout-ac 120 
        }
        elseif ($DisplayTimeMenu.Text -eq "150") {
            powercfg -change -monitor-timeout-dc 150
            powercfg -change -monitor-timeout-ac 150 
        }
        elseif ($DisplayTimeMenu.Text -eq "180") {
            powercfg -change -monitor-timeout-dc 180
            powercfg -change -monitor-timeout-ac 180
        }
        elseif ($DisplayTimeMenu.Text -eq "210") {
            powercfg -change -monitor-timeout-dc 210
            powercfg -change -monitor-timeout-ac 210
        }
        elseif ($DisplayTimeMenu.Text -eq "240") {
            powercfg -change -monitor-timeout-dc 240
            powercfg -change -monitor-timeout-ac 240 
        }
        Logger "[MESSAGE][RunTimeOut] - Invalid user input - Job was not executed"
        else {
            Logger "[MESSAGE][RunTimeOut] - Invalid user input - Job was not executed"
            return;
        }
    }
    catch [System.SystemException] {
        Logger "[ERROR][ChangeDisplayTime] - System Error: $_" 
        $MsgBoxError::Show("System Error! Contact your System Administrator.", $mailtaitel, "OK", "Error")
    }
    
}