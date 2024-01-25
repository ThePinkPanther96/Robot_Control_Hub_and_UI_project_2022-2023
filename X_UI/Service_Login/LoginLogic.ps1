# Get Path
$scriptDirectory = Split-Path $MyInvocation.MyCommand.Path
# Set working directory to the script directory
Set-Location $scriptDirectory

# Error message
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$MsgBoxError = [System.Windows.Forms.MessageBox]
$maintaitel = "X UI"

. "C:\X_UI\Control_Hub\Logic.ps1"

# Logger
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

function StopLockKeys {
    $ahkProcess = Get-Process | Where-Object {$_.Name -like "AutoHotkey"}
    if ($ahkProcess) {
        Stop-Process -Id $ahkProcess.Id
        Logger "[MESSAGE][StopLockKeys] - Service keys re-enabled"
    }
    else {
        Logger "[MESSAGE][StopLockKeys] -Service Keys are already enabled"
    }
}

function StartLockKeys {
    if (Get-Process | Where-Object {$_.Name -like "AutoHotkey"}){
        Logger "[MESSAGE][StartLockKeys] - Service keys Are Disabled"
        return;
    }
    else {
        Start-Process "C:\Program Files\AutoHotkey\AutoHotkey.exe" -ArgumentList "C:\X_UI\Resources\AutoHotkey\Service_Login_Keys_Lock.ahk"
        Logger "[MESSAGE][StartLockKeys] - Service keys where Disabled"
    }
}

function StatusAlign {
    # Center the Status label on the X-axis
    $statusWidth = $Status.PreferredSize.Width
    $statusX = ($secondForm.ClientSize.Width - $statusWidth) / 2
    $Status.Location = New-Object System.Drawing.Point($statusX, $Status.Location.Y)
  
    $secondForm.Controls.Remove($global:Status)
    $secondForm.Controls.Add($global:Status)
}

function DecryptString {
    param (
        [string]$Password
    )
    
    $decryptedPassword = $matchedRow.Password | ConvertTo-SecureString
    $plainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($decryptedPassword))
    $plainPassword
}

# Status message components
$global:Status = $null
$global:Status = SimpleText -FontSize 11 -LocationX 140 -LocationY 160 -Width 226 -ForeColor "Red" -String ""

function GetUserCredentials {
    param (
        [string]$Username,
        [string]$Password
    )

    try {
        if ($Username -and $Password) {
            $csvPath = "$SiteVarsPath\etc\credentials.csv"
            $csv = Import-Csv -Path $csvPath

            $matchedRow = $csv | Where-Object { $_.Username -cmatch $Username }
            if ($matchedRow) {
                $plainPassword = DecryptString -Password $Password

                if ($plainPassword -ceq $Password) {
                    LoginLogger "[MESSAGE][GetUserCredentials] - $Username logged in successfully. Form Closed."
                    StopLockKeys
                    start-sleep -Seconds 0.2
                    $firstForm.Dispose()
                    $secondForm.Dispose()
                }
                else {
                    LoginLogger "[MESSAGE][GetUserCredentials] - Incorrect credentials"
                    $global:Status.Text = "Incorrect username or password."
                }
            }
            else {
                LoginLogger "[MESSAGE][GetUserCredentials] - Incorrect credentials"
                $global:Status.Text = "Incorrect username or password."
            }
        }
        else {
            LoginLogger "[MESSAGE][GetUserCredentials] - Missing credentials"
            $global:Status.Text = "Missing credentials. Try again."
        }
    }
    catch {
        LoginLogger "[ERROR][GetUserCredentials] - System Error: $_"
        $MsgBoxError::Show("System Error! Contact your System Administrator or try again.", $maintaitel, "OK", "Error")
    }
    StatusAlign
}
