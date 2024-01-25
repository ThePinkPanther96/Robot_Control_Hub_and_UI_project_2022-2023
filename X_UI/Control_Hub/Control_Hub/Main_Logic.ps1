# Get Path
$scriptDirectory = Split-Path $MyInvocation.MyCommand.Path
# Set working directory to the script directory
Set-Location $scriptDirectory

# Init
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Error message
$MsgBoxError = [System.Windows.Forms.MessageBox]

# Get path
. "$scriptDirectory\Logic.ps1" #To Edit

#-----------------------------------------------[Logic Function]----------------------------------------------------------------

function Get-LastWindowsUpdates {
    try {
        Logger "[MESSAGE][Get-LastWindowsUpdates] - Getting updates history."
        $output = foreach ($update in (Get-CimInstance -ClassName Win32_QuickFixEngineering)) {
            $formattedDate = Get-Date $update.InstalledOn -Format "dd-MM-yyyy"
            $formattedKB = $update.HotFixID
            $type = if ($update.Description -like "*security*") {
                "Security" 
            } 
            elseif ($update.Description -like "*critical*") {
                "Critical" 
            } 
            else {
                "Other Update"
            }
            "`n$formattedDate - $formattedKB - $type`n"
        }
        return $output
    }
    catch {
        Logger "[ERROR][Get-LastWindowsUpdates] - System Error: $_"
        $MsgBoxError::Show("Unexpected error occurred while trying to get update history.", $mailtaitel, "OK", "Error")
    }
}

function Get-WindowsInformation {
    try {
        Logger "[MESSAGE][Get-WindowsInformation] - Getting system information."
        $os = Get-CimInstance -ClassName Win32_OperatingSystem

        $windowsType = $os.Caption
        $windowsVersion = $os.Version
        $windowsBuild = "OS Build $($os.BuildNumber)" #.$($os.BuildRevision)"

        $output = @"

Windows Type: $windowsType

Windows Version: $windowsVersion

Windows Build: $windowsBuild
"@
        return $output
    }
    catch {
        Logger "[ERROR][Get-WindowsInformation] - System Error: $_"
        $MsgBoxError::Show("An error occurred while trying to get system information.", $mailtaitel, "OK", "Error")
    }
}

function GetWindowsDefenderInfo {
    try {
        $DefenderStatus = Get-MpComputerStatus

        $AMServiceVersion = $DefenderStatus.AMServiceVersion
        $AMEngineVersion = $DefenderStatus.AMEngineVersion
        $AntispywareSignatureVersion = $DefenderStatus.AntispywareSignatureVersion
        $AntivirusSignatureVersion = $DefenderStatus.AntivirusSignatureVersion

        # Format the output
        $output = @"
Antimalware Client Version: $AMServiceVersion

Engine Version: $AMEngineVersion

Antivirus Version: $AntispywareSignatureVersion

Antispyware Version: $AntivirusSignatureVersion
"@
        return $output
    }
    catch {
        Logger "[ERROR][GetWindowsDefenderInfo] - System Error: $_"
        [System.Windows.Forms.MessageBox]::Show("An error occurred while trying to get Windows Defender information.", "Error", "OK", "Error")
    }
}

function ShowXMLContent {
    param(
        [string]$Node = "",
        [string]$FilePath,
        [string]$File,
        [string]$Directory
    )
    Add-Type -Path "$scriptDirectory\FastColoredTextBox.dll"
    $Path = Join-Path $FilePath $Directory $File
    $xml = [xml](Get-Content -Path $Path)

    if ([string]::IsNullOrWhiteSpace($Node)) {
        $content = Format-Xml $xml.OuterXml
    } else {
        $selectedNode = $xml.SelectSingleNode($Node)
        if ($selectedNode) {
            $content = Format-Xml $selectedNode.OuterXml
        } else {
            Write-Host "Node '$Node' not found in the XML file."
            return
        }
    }
    # Remove the existing panel if it exists
    if ($global:OpenButton -and $global:OpenButton.Tag -eq "ContentPanel") {
        $global:Form.Controls.Remove($global:OpenButton)
    }
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Width = 656
    $panel.Height = 543
    $panel.Location = New-Object System.Drawing.Point(520, 137)
    $panel.Tag = "ContentPanel"

    $fctb = New-Object FastColoredTextBoxNS.FastColoredTextBox
    $fctb.Language = 'XML'
    $fctb.Font = New-Object System.Drawing.Font("Consolas", 11)
    $fctb.ReadOnly = $true
    $fctb.BackColor = '#EFEFEF'
    $fctb.Width = $panel.Width
    $fctb.Height = $panel.Height
    $fctb.BorderStyle = "Fixed3D"
    $fctb.Text = $content

    $panel.Controls.Add($fctb)
    $global:Form.Controls.Add($panel)
    $global:OpenButton = $panel

    return $content
}

function Format-Xml {
    param(
        [string]$Xml
    )
    $output = New-Object System.IO.StringWriter
    $writer = New-Object System.Xml.XmlTextWriter $output
    $writer.Formatting = "indented"
    $writer.Indentation = 2

    $xmlDoc = New-Object System.Xml.XmlDocument
    $xmlDoc.LoadXml($Xml)

    $xmlDoc.WriteContentTo($writer)
    $writer.Flush()

    $output.ToString()
}

function XMLNodeStatus-Checkbox {
    param (
        [Parameter(Mandatory=$true)][string]$Text,
        [Parameter(Mandatory=$false)][bool]$Checked = $false,
        [Parameter(Mandatory=$true)][string]$LocationX,
        [Parameter(Mandatory=$true)][string]$LocationY,
        [int]$FontSize = 12,
        [int]$Width = 150
    )

    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $Text
    $checkbox.Checked = $Checked
    $checkbox.Width = $Width
    $checkbox.Location = New-Object System.Drawing.Point($LocationX, $LocationY)
    $checkbox.BackColor = '#000000'
    $checkbox.ForeColor = '#939598'
    $font = New-Object System.Drawing.Font("Microsoft Sans Serif", $FontSize, [System.Drawing.FontStyle]::Regular)
    $checkbox.Font = $font

    $global:Form.Add_Load({
        $serviceNeeded = $xml.ClinicalFlowConfig.ServiceNeeded
        $checkbox.Checked = ($serviceNeeded -eq 'true')
    })

    $eventHandler = {
        $isChecked = $checkbox.Checked
        Update-ServiceNeededNode $isChecked
    }

    $global:Form.Controls.Add($checkbox)
    $checkbox.Add_CheckedChanged($eventHandler)
    return $checkbox
}

function Update-ServiceNeededNode([bool]$value) {
    $xmlPath = 'C:\X Robotics\X_app\Config\Workstation\ClinicalFlowConfig.xml'
    $xml = [xml](Get-Content -Path $xmlPath)
    $xml.ClinicalFlowConfig.ServiceNeeded = $value.ToString().ToLower()
    $xml.Save($xmlPath)
}

function Get-XmlNodeValue {
    param (
        [string]$Path,
        [string]$File,
        [string]$Node
    )
    
    $xmlPath = Join-Path -Path $Path -ChildPath $File

    if (Test-Path $xmlPath) {
        $xmlContent = Get-Content $xmlPath
        $xml = [xml]$xmlContent
        $nodeValue = $xml.SelectSingleNode("//$Node") | ForEach-Object { $_.'#text' }

        if ($nodeValue) {
            return $nodeValue
        } else {
            return "Node '$Node' not found in the file."
        }
    } else {
        return "File not found at path: $xmlPath"
    }
}

# Function to update the read-only textbox with the selected node's value
function Update-ReadOnlyTextBox {
    param (
        [System.Windows.Forms.ComboBox]$DropDownMenu,
        [string]$Path,
        [string]$File,
        [System.Windows.Forms.TextBox]$ReadOnlyTextBox
    )

    $selectedNode = $DropDownMenu.SelectedItem
    if ($selectedNode) {
        $nodeValue = Get-XmlNodeValue -Path $Path -File $File -Node $selectedNode
        $ReadOnlyTextBox.Text = $nodeValue
    }
}

#-----------------------------------------------[Event Handlers]----------------------------------------------------------------

function ViweXML {
    param (
        [string]$FilePath = "C:\X Robotics\X_app\Config\",
        [string]$Directory,
        [string]$File,
        [string]$Node = ""
    )
    if ($File -and $Directory) {
        try {
            Logger "[MESSAGE][ViweXML] - Displaying $File"
            ShowXMLContent -FilePath $FilePath -Directory $Directory -File $File
        }
        catch {
            Logger "[ERROR][ViweXML] - System Error: $_"
            $MsgBoxError::Show("Database Error! Could not get database contents.", $mailtaitel, "OK", "Error")
        }
    }
    else {
        Logger "[MESSAGE][ViweXML] - Missing input. Function stopped"
        $MsgBoxError::Show("Missing Credentials. Selecting a Database and Directory are mandatory.", $maintaitel, "OK", "Warning")
    }
}

function CreateUser {
    param (
        [string]$Password,[string]$ConfirmPassword,[string]$Username,[string]$FullName
    )
    try {
        if($Password -and $ConfirmPassword -and $UsernameText -and $FullName){
            
            if ($ConfirmPassword -eq $Password) {
                $pattern = "(?=.*[A-Z])(?=.*[a-z])(?=.*\W)(?=.{8,})"
                
                if ($Password -match $pattern) {
                    [System.Windows.Forms.Cursor]::Current = 'WaitCursor' # Loading
                    AddDataToCSV -Username $Username -Password $Password -FullName $FullName
                }
                else {
                    Logger "[MESSAGE][CreateUser] - Password do not satisfy requerments. Job was not executed"
                    $MsgBoxError::Show("Passwords must be at least 8 characters long, 
and include at least one capital and lowercase letters, special symbol, and a number!", $maintaitel, "OK", "Warning")   
                }
            }
            else {
                Logger "[MESSAGE][CreateUser] - Passwords do not match. Job was not executed"
                $MsgBoxError::Show("Passwords Do Not Match. Try Agian.", $maintaitel, "OK", "Warning")  
            }
        }
        else {
            Logger "[MESSAGE][CreateUser] - Missing user input - Job was not executed"
            $MsgBoxError::Show("Missing Credentials. Try Agian.", $maintaitel, "OK", "Warning") 
        }  
    }
    catch {
        Logger "[ERROR][CreateUser] - System Error: $_"
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











# Temp
function FuncA {
    Write-Host "Red" -ForegroundColor "Red"
}
  
# Temp
function FuncB {
    Write-Host "Green" -ForegroundColor "Green"
}
  
# Temp
function Update-XML {
    param (
        [string]$Node,[string]$NodeContent,[string]$FilePath
    )   
    try {
        UpdateXML -FilePath $FilePath -Node $Node -NodeContent $NodeContent  
    }
    catch {
          
    }
}