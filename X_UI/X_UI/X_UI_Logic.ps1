# XA UI 1.0.0 Logic
#------------------------------------------------------------[Variables]------------------------------------------------------------

# Get Path
$scriptDirectory = Split-Path $MyInvocation.MyCommand.Path
# Set working directory to the script directory
Set-Location $scriptDirectory

#--------------------------------------------------------------[Script]-------------------------------------------------------------

# Error message
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$MsgBoxError = [System.Windows.Forms.MessageBox]
$maintaitel = "X UI"


# Logger
Function Logger()
{
 param
    (
    [Parameter(Mandatory=$true)] [string] $Message
    )
 
    Try {
        $LogFile = "C:\X_UI\Logs\X_UI_Event_log.log"

        #Add Content to the Log File
        $TimeStamp = (Get-Date).toString("dd/MM/yyyy HH:mm:ss:fff tt")
        $Line = "$TimeStamp - $Message"
        Add-content -Path $Logfile -Value $Line
 
        Write-host "Message: '$Message' Has been Logged to File: $LogFile"
    }
    Catch {
        Write-host -f Red "Error:" $_.Exception.Message
    }
}

Function LoginLogger()
{
 param
    (
    [Parameter(Mandatory=$true)] [string] $Message
    )
    Try {
        #Frame Log File with Current Directory and date
        $LogFile = "C:\X_UI\Logs\X_UI_Event_Login_log.log"
 
        #Add Content to the Log File
        $TimeStamp = (Get-Date).toString("dd/MM/yyyy HH:mm:ss:fff tt")
        $Line = "$TimeStamp - $Message"
        Add-content -Path $Logfile -Value $Line
 
        Write-host "Message: '$Message' Has been Logged to File: $LogFile"
    }
    Catch {
        Write-host -f Red "Error:" $_.Exception.Message
    }
}

function LockKeys {
    if (Get-Process | Where-Object {$_.Name -like "AutoHotkey"}){
        Logger "[MESSAGE][TrackProcess] - Keys Are Disabled"
        return;
    }
    else {
        Start-Process "C:\Program Files\AutoHotkey\AutoHotkey.exe" -ArgumentList "C:\X_UI\Resources\AutoHotkey\Medical_Keys_Lock.ahk"
        Logger "[MESSAGE][TrackProcess] - Keys where Disabled"
    }
}

function GetUser {
    try {
        $currentUsername = $env:USERNAME
        LoginLogger "[MESSAGE][GetUser] - $currentUsername has logged in to Windows"
    }
    catch {
        LoginLogger "[MESSAGE][GetUser] - Error! $_"
    }
}

function RebootComputer {
    try {
        Logger "[MESSAGE][Reboot] - System Rebooted Successfully"
        Restart-Computer -Force -Confirm:$false
    }
    catch {
        Logger "[ERROR][Reboot] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator or try again.", $maintaitel, "OK", "Error") 
    }
}

function ShutdownPC {
    try {
        Logger "[MESSAGE][Shutdown] - System Shutdown Successfully"
        Stop-Computer -ComputerName "localhost" -Force
    }
    catch {
        Logger "[ERROR][Shutdown] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator or try again.", $maintaitel, "OK", "Error")
    }
}


function OnScreenKeyboard {
    try {
        $oskPath = "${Env:windir}\System32\osk.exe"
        Start-Process -FilePath $oskPath
    }   
    catch {
        Logger "[ERROR][OnScreenKeyboard] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator or try again.", $maintaitel, "OK", "Error")
    }
}

function ShutdownComputer {
    try {
        Logger "[FUNCTION][ShutdownComputer] - User Prassed ShutdownComputer"
        ShutdownPC
    }
    catch {
        Logger "[ERROR][ShutdownComputer] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator or try again.", $maintaitel, "OK", "Error") 
    }
}

function ChangeUser {
    try {
        LoginLogger "[MESSAGE][ChangeUser] - User logged out."
        shutdown /l
    }
    catch {
        Logger "[ERROR][ChangeUser] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator or try again.", $maintaitel, "OK", "Error")
    }
    
}

function RunX {
    try {
        Logger "[FUNCTION][RunX] - User Launched X"
        Start-Process -FilePath "$scriptDirectory\Resources\RunX.lnk" #-Wait
    }
    catch {
        Logger "[ERROR][RunX] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator or try again.", $maintaitel, "OK", "Error")
    }
}

function CloseForm {
    try {
        $SeecondForm.Close()
    }
    catch {
        Logger "[ERROR][CloseForm] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator.", $maintaitel, "OK", "Error")
    }   
}

function RunSimulation {
    try {
        $SecondForm.Close()
        Start-Process -FilePath "$scriptDirectory\Resources\HostSimulator.lnk"
    }
    catch {
        Logger "[ERROR][RunSimulation] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator.", $maintaitel, "OK", "Error")
    }   
}

function RunCalibration {
    try {
        $SecondForm.Close()
        Start-Process -FilePath "$scriptDirectory\Resources\RobotCallibration.lnk"
    }
    catch {
        Logger "[ERROR][RunCalibration] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator.", $maintaitel, "OK", "Error")
    }   
}

function OpenVideo {
    try {
        $SecondForm.Close()
        Start-Process -FilePath "$scriptDirectory\Resources\InstructionVideo.lnk"
        
    }
    catch {
        Logger "[ERROR][OpenVideo] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator.", $maintaitel, "OK", "Error")
    }   
}

function RunExport {
    try {
        $SecondForm.Close()
        Start-Process -FilePath "$scriptDirectory\Resources\ExportProceduresData"
    }
    catch {
        Logger "[ERROR][RunExport] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator.", $maintaitel, "OK", "Error")
    }
}

function OpenAppsDialog {
    try {
        $scriptPath = "$scriptDirectory\AppsDialog.ps1"
        PowerShell.exe -File $scriptPath # -Wait
    }
    catch {
        Logger "[ERROR][OpenAppsDialog] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator.", $maintaitel, "OK", "Error")
    }   
}
