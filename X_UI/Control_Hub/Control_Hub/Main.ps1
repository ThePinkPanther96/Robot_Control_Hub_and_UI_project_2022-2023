# Get Path
$scriptDirectory = Split-Path $MyInvocation.MyCommand.Path
# Set working directory to the script directory
Set-Location $scriptDirectory

. "$scriptDirectory\Logic.ps1"
. "$scriptDirectory\Main_Logic.ps1"

# Init PowerShell Gui
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.ComponentModel
# Define functions to create and hide the console window
$hideConsoleScript = {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public static class Win32 {
        [DllImport("kernel32.dll")]
        public static extern Boolean AllocConsole();

        [DllImport("kernel32.dll")]
        public static extern Boolean FreeConsole();

        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();

        [DllImport("user32.dll")]
        public static extern Boolean ShowWindow(IntPtr hWnd, Int32 nCmdShow);

        public const Int32 SW_HIDE = 0;
    }
"@
}

# Hide the console window
& $hideConsoleScript
[Win32]::AllocConsole() | Out-Null
[Win32]::ShowWindow([Win32]::GetConsoleWindow(), [Win32]::SW_HIDE) | Out-Null

#------------------------------------------------------------[Main Menu]---------------------------------------------------------
# Create a new form
$maintaitel = "Control Hub"
$global:Form = New-Object system.Windows.Forms.Form
#$global:Form.MaximumSize = New-Object Drawing.Size(1260, 750)
$global:Form.StartPosition = 'CenterScreen'
$global:Form.ClientSize = '1200,700'
$global:Form.text = $maintaitel
$global:Form.BackColor = "#ededed"
$global:Form.FormBorderStyle = 'Fixed3D'
$global:Form.BackgroundImageLayout = "Center"
$global:Form.ProcessWindowStyle.Hidden
$global:Form.MaximizeBox = $False
$global:Form.ShowInTaskbar = $true # To Edit
$global:Form.MaximizeBox = $false
$global:Form.MinimizeBox = $true
#$global:Form.MinimumSize = $Form.Size
#$global:Form.MaximumSize = $Form.Size
$Image = [System.Drawing.Image]::FromFile("$scriptDirectory\Logos\ControlHubBackground.png")
$global:Form.BackgroundImage = $Image
$global:Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$scriptDirectory\Logos\Control_Hub.ico")

# Enable double buffering
$global:Form.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance).SetValue($global:Form, $true, $null)

# Error message
$MsgBoxError = [System.Windows.Forms.MessageBox]
[System.Windows.Forms.Application]::EnableVisualStyles()

#------------------------------------------------------------------[Controls]---------------------------------------------------------------------
# Create a global variable to track the currently open button
$global:OpenButton = $null
$global:ContentButtons = @()

function Button () {
    param (
        [string]$Text,[string]$ForeColor = "Black",[string]$BackColor = "#D9D9D9",
        [int]$FontSize = '13',[int]$Width = 200,[int]$Height = 35,
        [int]$LocationX = 10,[int]$LocationY, [bool]$Enabled = $True
    )
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.FlatAppearance.BorderSize = 0
    $Btn.Text = $Text
    $Btn.Width = $Width
    $Btn.Height = $Height
    $Btn.ForeColor = $ForeColor
    $Btn.BackColor = $BackColor
    $Btn.Enabled = $Enabled
    $Btn.Location = New-Object System.Drawing.Point($LocationX, $LocationY)
    $Btn.Font = "Microsoft Sans Serif,$FontSize"
    $Btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    
    $global:Form.Controls.Add($Btn)
    return $Btn
}

function TextBox () {
    param (
        [string]$FontSize = 11,
        [int]$Width = 200,[int]$Height = 30,[int]$LocationX,[int]$LocationY,
        [bool]$Visable = $True, [bool]$Multiline = $False, $ReadOnly = $False
    )
    $TextBox = New-Object system.Windows.Forms.TextBox
    $TextBox.width = $Width
    $TextBox.height = $Height
    $TextBox.location = New-Object System.Drawing.Point($LocationX, $LocationY)
    $TextBox.Font = "Microsoft Sans Serif,$FontSize"
    $TextBox.Visible = $Visable
    $TextBox.multiline = $Multiline
    $TextBox.ReadOnly = $ReadOnly
    #$TextBox.add_Gotfocus({$TextBox.Clear()})

    $global:Form.Controls.Add($TextBox)
    return $TextBox
}

function DropdownMenu () {
    param (
        [int]$Width,[int]$Index = -1,[int]$LocationX,[int]$LocationY,
        [string]$FontSize = '13',[string[]]$Arguments,
        [bool]$AutoSize = $True
    )    
    $DropdownMenu = New-Object system.Windows.Forms.ComboBox
    $DropdownMenu.width = $Width
    $DropdownMenu.SelectedIndex = $Index
    $DropdownMenu.location = New-Object System.Drawing.Point($LocationX, $LocationY)
    $DropdownMenu.Font = "Microsoft Sans Serif,$FontSize"
    $DropdownMenu.DropDownStyle = 'DropDownList'
    $DropdownMenu.autosize = $AutoSize
    
    @($Arguments)| ForEach-Object {
        [void] $DropdownMenu.Items.Add($_)
    }
    $global:Form.Controls.Add($DropdownMenu)
    return $DropdownMenu
}

function DropdownMenuContant () {
    param (
        [int]$Width,[int]$Index = -1,
        [int]$LocationX,[int]$LocationY,
        [string]$FontSize = '13',[string[]]$DirectoryPaths,
        [bool]$AutoSize = $True,[string]$AdditionalString = $null
    )
    $DropdownMenu = New-Object System.Windows.Forms.ComboBox
    $DropdownMenu.Width = $Width
    $DropdownMenu.SelectedIndex = $Index
    $DropdownMenu.Location = New-Object System.Drawing.Point($LocationX, $LocationY)
    $DropdownMenu.Font = "Microsoft Sans Serif, $FontSize"
    $DropdownMenu.DropDownStyle = 'DropDownList'
    $DropdownMenu.AutoSize = $AutoSize
    
    foreach ($DirectoryPath in $DirectoryPaths) {
        if (Test-Path -Path $DirectoryPath -PathType Container) {
            $Files = Get-ChildItem -Path $DirectoryPath -File
            foreach ($File in $Files) {
                [void]$DropdownMenu.Items.Add($File.Name)
            }
        }
    }
    if ($AdditionalString) {
        [void]$DropdownMenu.Items.Add($AdditionalString)
    }
    $global:Form.Controls.Add($DropdownMenu)
    return $DropdownMenu
}

function SimpleText () {
    param (
        [string]$String,[string]$FontSize,
        [string]$ForeColor = "#000000",[string]$BackColor = "Transparent",
        [int]$Width = 225,[int]$Height = 25,[int]$LocationX,[int]$LocationY,
        [bool]$AutoSize = $false
    )
    $SimpleText = New-Object System.Windows.Forms.Label
    $SimpleText.AutoSize = $AutoSize
    $SimpleText.Text = $String
    $SimpleText.Width = $Width
    $SimpleText.Height = $Height
    $SimpleText.Location = New-Object System.Drawing.Point($LocationX, $LocationY)
    $SimpleText.Font = "Microsoft Sans Serif,$FontSize"
    $SimpleText.ForeColor = $ForeColor
    $SimpleText.BackColor = $BackColor

    $global:Form.Controls.Add($SimpleText)
    return $SimpleText
}

function New-Checkbox () {
    param (
        [Parameter(Mandatory=$true)][string]$Text,
        [Parameter(Mandatory=$false)][bool]$Checked = $false,
        [Parameter(Mandatory=$true)][string]$LocationX,
        [Parameter(Mandatory=$true)][string]$LocationY,
        [int]$FontSize = 11,
        [int]$Width = 220
    )
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $Text
    $checkbox.Checked = $Checked
    $checkbox.Width = $Width
    $checkbox.Location = New-Object System.Drawing.Point($LocationX, $LocationY)
    $checkbox.Font = "Microsoft Sans Serif,$FontSize"
    $eventHandler = {
        if ($global:checkBox.Checked) {
            Write-Host $true 
        } 
        else {
            Write-Host $false 
        }
    }
    $global:Form.Controls.Add($checkbox)
    $checkbox.Add_CheckedChanged($eventHandler) 
    return $checkbox
}

function CloseOpenButton {
    if ($null -ne $global:OpenButton) {
        # Close the content of the currently open button
        $global:Form.Controls | Where-Object { $_.Tag -eq "ContentPanel" } | ForEach-Object {
            $global:Form.Controls.Remove($_)
        }
        # Reset the OpenButton variable
        $global:OpenButton = $null
    }
    # Remove the additional buttons from the form
    $global:ContentButtons | ForEach-Object {
        $global:Form.Controls.Remove($_)
    }
    $global:ContentButtons = @()
}

#---------------------------------------------------------------[Tabs]------------------------------------------------------------

$SystemSttingsTab = Button -BackColor '#F58933' -ForeColor '#EFEFEF' -FontSize '13' -Width 75 -Height 27 -LocationY 85 -LocationX 6 -Text 'System'
$SystemSttingsTab.Add_Click({ SystemSttingsTab })

$UsersSettingsTab = Button -BackColor '#F58933' -ForeColor '#EFEFEF' -FontSize '13' -Width 75 -Height 27 -LocationY 85 -LocationX 93 -Text 'Users'
$UsersSettingsTab.Add_Click({ UsersSettingsTab })

$XappSttingsTab = Button -BackColor '#F58933' -ForeColor '#EFEFEF' -FontSize '13' -Width 75 -Height 27 -LocationY 85 -LocationX 183 -Text 'X App'
$XappSttingsTab.Add_Click({ XappSttingsTab })

$AboutTab = Button -BackColor '#F58933' -ForeColor '#EFEFEF' -FontSize '13' -Width 75 -Height 27 -LocationY 85 -LocationX 272 -Text 'About'
$AboutTab.Add_Click({ AboutTab })

# Service Needed Checkbox
$initialServiceNeeded = [bool]($xml.ClinicalFlowConfig.ServiceNeeded -eq 'true' )
$global:checkBox = XMLNodeStatus-Checkbox -Text "Service Needed" -LocationX 937 -LocationY 29 -Checked $initialServiceNeeded
# Load the XML file and get the initial state of the <ServiceNeeded> node
$xmlPath = 'C:\X Robotics\X_app\Config\Workstation\ClinicalFlowConfig.xml'
$xml = [xml](Get-Content -Path $xmlPath)

$HelpBtn = Button -BackColor '#000000' -FontSize '20' -Width 35 -Height 28 -LocationY 25 -LocationX 1150
$HelpImage = [System.Drawing.Image]::FromFile("$scriptDirectory\Logos\QuestionMark1.png")
$HelpBtn.Image = $HelpImage
$HelpBtn.Add_Click({ $null })

$KeyBoardBtn = Button -BackColor '#000000' -FontSize '20' -Width 35 -Height 28 -LocationY 25 -LocationX 1099
$KeyBoardBtnImage = [System.Drawing.Image]::FromFile("$scriptDirectory\Logos\Keyboard.png")
$KeyBoardBtn.Image = $KeyBoardBtnImage
$KeyBoardBtn.Add_Click({ OnScreenKeyboard })

$Info = SimpleText -FontSize "8" -Width 200 -Height 16 -LocationX 10 -LocationY 680 -String "Copyright © Gal R 2023-2024 | v1.0"

function SystemSttingsTab {
    CloseOpenButton

    $SystemPrefrencesBtn = Button -LocationY 130 -LocationX 10 -Text "System Preferences"
    $SystemPrefrencesBtn.Add_Click({ SystemPrefrencesBtn })
    
    $SystemBackupAndRestore = Button -LocationY 165 -LocationX 10 -Text "Backup and Restore"
    $SystemBackupAndRestore.Add_Click({ SystemBackupAndRestore })

    $NetworkSettings = Button -LocationY 200 -Text "Network Settings"
    $NetworkSettings.Add_Click({ NetworkSettings })

    $VarList = @($SystemPrefrencesBtn,$SystemBackupAndRestore,$NetworkSettings)
    foreach ($Text in $VarList){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }

    $global:ContentButtons = @($VarList)
    $global:OpenButton = $SystemPrefrencesBtn   
}

function UsersSettingsTab {
    CloseOpenButton

    $CreateUserSideBtn = Button -LocationY 130 -Text "Create New User"
    $CreateUserSideBtn.Add_Click({ CreateUserSideBtn })

    $DeleteUserSideBtn = Button -LocationY 165 -Text "Delete User"
    $DeleteUserSideBtn.Add_Click({ DeleteUserSideBtn })

    $ModifyUserSideBtn = Button -LocationY 200 -Text "Modify User"
    $ModifyUserSideBtn.Add_Click({ ModifyUserSideBtn })

    $ViewUserSideBtn = Button -LocationY 235 -Text "View all Users"
    $ViewUserSideBtn.Add_Click({ ViewUserSideBtn })

    $VarList = @($ViewUserSideBtn,$ModifyUserSideBtn,$DeleteUserSideBtn,$CreateUserSideBtn)
    foreach ($Text in $VarList){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }

    $global:ContentButtons = @($VarList)
    $global:OpenButton = $CreateUserSideBtn     
}

function XappSttingsTab {
    CloseOpenButton
    
    $SpesificSiteConfigBtn = Button -LocationY 130 -Text "Site Spesific Settings"
    $SpesificSiteConfigBtn.Add_Click({ SpesificSiteConfigBtn })

    $CTScannersConfig = Button -LocationY 165 -Text "CT Scanners Settings"
    $CTScannersConfig.Add_Click({ CTScannersConfig })

    $DataBaseViewBtn = Button -LocationY 200 -Text "Database Viewer"
    $DataBaseViewBtn.Add_Click({ DataBaseViewBtn })

    $NewSiteConfig = Button -LocationY 235 -Text "New site Configurator"
    $NewSiteConfig.Add_Click({ NewSiteConfig })

    $VarList = @($SpesificSiteConfigBtn,$CTScannersConfig,$DataBaseViewBtn,$NewSiteConfig)
    foreach ($Text in $VarList){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }

    $global:ContentButtons = @($VarList)
    $global:OpenButton = $SpesificSiteConfigBtn
}

function AboutTab {
    CloseOpenButton

    $SystemAndSecurityBtn = Button -LocationY 130 -Text "System and Security"
    $SystemAndSecurityBtn.Add_Click({ SystemAndSecurityBtn })

    $ApplicationBtn = Button -LocationY 165 -Text "Windows Applications"
    $ApplicationBtn.Add_Click({ ApplicationBtn })

    $XApplicationsBtn = Button -LocationY 200 -Text "X Applications"
    $XApplicationsBtn.Add_Click({ XApplicationsBtn })

    $ControllersBtn = Button -LocationY 235 -Text "Controllers and Drivers"
    $ControllersBtn.Add_Click({ ControllersBtn })

    $WindowsUpdateHistory = Button -LocationY 270 -Text "Update History"
    $WindowsUpdateHistory.Add_Click({ WindowsUpdateHistory })

    $VarList = @($SystemAndSecurityBtn,$ApplicationBtn,$XApplicationsBtn,$ControllersBtn,$WindowsUpdateHistory)
    foreach ($Text in $VarList){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }

    $global:ContentButtons = @($VarList)
    $global:OpenButton = $SystemAndSecurityBtn

}


#---------------------------------------------------------------[Side Bar]-----------------------------------------------------------

function SystemPrefrencesBtn {
    CloseOpenButton

    $SystemPrefrencesBtn = Button -LocationY 130 -LocationX 10 -Text "System Preferences"
    $SystemPrefrencesBtn.Add_Click({ $null })
    
    $SystemBackupAndRestore = Button -LocationY 165 -LocationX 10 -Text "Backup and Restore"
    $SystemBackupAndRestore.Add_Click({ SystemBackupAndRestore })

    $NetworkSettings = Button -LocationY 200 -Text "Network Settings"
    $NetworkSettings.Add_Click({ NetworkSettings })

    $Titel = SimpleText -FontSize 16 -LocationX 243 -LocationY 135 -String "System Preferences"

    $Align = @($SystemPrefrencesBtn,$SystemBackupAndRestore,$NetworkSettings)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }

    $VarList = @($SystemPrefrencesBtn,$SystemBackupAndRestore,$NetworkSettings,$Titel)
    $global:ContentButtons = @($VarList)
    $global:OpenButton = $SystemPrefrencesBtn
}

function SystemBackupAndRestore {
    CloseOpenButton

    $SystemPrefrencesBtn = Button -LocationY 130 -LocationX 10 -Text "System Preferences"
    $SystemPrefrencesBtn.Add_Click({ SystemPrefrencesBtn })
    
    $SystemBackupAndRestore = Button -LocationY 165 -LocationX 10 -Text "Backup and Restore"
    $SystemBackupAndRestore.Add_Click({ $null })

    $NetworkSettings = Button -LocationY 200 -Text "Network Settings"
    $NetworkSettings.Add_Click({ NetworkSettings })

    $Titel = SimpleText -FontSize 16 -LocationX 243 -LocationY 135 -String "Backup and Restore"

    $Align = @($SystemPrefrencesBtn,$SystemBackupAndRestore,$NetworkSettings)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }

    $VarList = @($SystemPrefrencesBtn,$SystemBackupAndRestore,$NetworkSettings,$Titel)
    $global:ContentButtons = @($VarList)
    $global:OpenButton = $SystemPrefrencesBtn
}

function GetCompleteIPAddress($textBox1, $textBox2, $textBox3, $textBox4) {
    $ipParts = @($textBox1, $textBox2, $textBox3, $textBox4)

    # Validate input and build the IP address
    $valid = $true
    foreach ($part in $ipParts) {
        if ($part -notmatch '^\d{1,3}$' -or [int]$part -lt 0 -or [int]$part -gt 255) {
            $valid = $false
            break
        }
    }

    if ($valid) {
        $ipAddress = $ipParts -join '.'
        return $ipAddress
    } else {
        return $null
    }
}

# Function to validate and update IP address
function UpdateIPAddress($textBox) {
    if ($textBox.Text -notmatch '^\d{1,3}$' -or [int]$textBox.Text -lt 0 -or [int]$textBox.Text -gt 255) {
        $textBox.Text = ""
        $textBox.BackColor = "LightPink"
    } else {
        $textBox.BackColor = [System.Drawing.SystemColors]::Window
    }

    $completeIPAddress = GetCompleteIPAddress -textBox1 $global:IPAddres.text -textBox2 $global:IPAddres1.text -textBox3 $global:IPAddres2.text -textBox4 $global:IPAddres3.text
    if ($completeIPAddress) {
        Write-Host  $completeIPAddress
    } else {
        Write-Host "Invalid IP Address"
    }
}


function NetworkSettings {
    CloseOpenButton

    $SystemPrefrencesBtn = Button -LocationY 130 -LocationX 10 -Text "System Preferences"
    $SystemPrefrencesBtn.Add_Click({ SystemPrefrencesBtn })
    
    $SystemBackupAndRestore = Button -LocationY 165 -LocationX 10 -Text "Backup and Restore"
    $SystemBackupAndRestore.Add_Click({ SystemBackupAndRestore })

    $NetworkSettings = Button -LocationY 200 -Text "Network Settings"
    $NetworkSettings.Add_Click({ $null })

    $Titel = SimpleText -FontSize 16 -LocationX 243 -LocationY 135 -String "Network Settings"

    $Titel1 = SimpleText -FontSize 11 -LocationX 440 -LocationY 190 -String "Select Network Adapter:"
    $global:SelectNetDrop = DropdownMenu -Width 185 -Height 30 -LocationX 443 -LocationY 215 -Arguments "CT","X App" -FontSize 11
    
    $Titel2 = SimpleText -FontSize 11 -LocationX 245 -LocationY 190 -String "IP Address:"
    $global:IPAddres = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 249 -LocationY 215
    $global:IPAddres1 = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 283 -LocationY 215
    $global:IPAddres2 = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 317 -LocationY 215
    $global:IPAddres3 = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 351 -LocationY 215 
    
    $Titel3 = SimpleText -FontSize 11 -LocationX 245 -LocationY 255 -String "Subnet Mask:" -Width 100
    $global:SubnetMask = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 249 -LocationY 280
    $global:SubnetMask1 = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 283 -LocationY 280
    $global:SubnetMask2 = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 317 -LocationY 280
    $global:SubnetMask3 = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 351 -LocationY 280

    $Titel4 = SimpleText -FontSize 11 -LocationX 245 -LocationY 320 -String "Default Gateway (optional):"
    $global:DefGateway = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 249 -LocationY 345
    $global:DefGateway1 = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 283 -LocationY 345
    $global:DefGateway2 = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 317 -LocationY 345
    $global:DefGateway3 = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 351 -LocationY 345

    $Titel5 = SimpleText -FontSize 11 -LocationX 245 -LocationY 420 -String "Primary DNS (optional):"
    $global:PrimaryDNS = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 249 -LocationY 445
    $global:PrimaryDNS1 = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 283 -LocationY 445
    $global:PrimaryDNS2 = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 317 -LocationY 445
    $global:PrimaryDNS3 = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 351 -LocationY 445

    $Titel6 = SimpleText -FontSize 11 -LocationX 245 -LocationY 485 -String "Secondary DNS (optional):"
    $global:SecondDNS = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 249 -LocationY 510
    $global:SecondDNS1 = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 283 -LocationY 510
    $global:SecondDNS2 = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 317 -LocationY 510
    $global:SecondDNS3 = TextBox -FontSize 12 -Width 35 -Height 30 -LocationX 351 -LocationY 510

    $global:checkBox = New-Checkbox -Text "Network Adapter Enabled" -LocationX 443 -LocationY 260 -Checked $false

    # Add TextChanged and Validating event handlers
    $global:IPAddres.Add_TextChanged({ UpdateIPAddress $global:IPAddres })
    $global:IPAddres.Add_Validating({ UpdateIPAddress $global:IPAddres })

    $global:IPAddres1.Add_TextChanged({ UpdateIPAddress $global:IPAddres1 })
    $global:IPAddres1.Add_Validating({ UpdateIPAddress $global:IPAddres1 })

    $global:IPAddres2.Add_TextChanged({ UpdateIPAddress $global:IPAddres2 })
    $global:IPAddres2.Add_Validating({ UpdateIPAddress $global:IPAddres2 })

    $global:IPAddres3.Add_TextChanged({ UpdateIPAddress $global:IPAddres3 })
    $global:IPAddres3.Add_Validating({ UpdateIPAddress $global:IPAddres3 })

    # Create the "Proceed" button
    $UpdateBtn = Button -Width 170 -Text "Proceed" -LocationX 250 -LocationY 641
    $UpdateBtn.Add_Click({ $completeIPAddress })    

    $textboxes = @($global:IPAddres,$global:IPAddres1,$global:IPAddres2,$global:IPAddres3,
    $global:SubnetMask,$global:SubnetMask1,$global:SubnetMask2,$global:SubnetMask3,
    $global:DefGateway,$global:DefGateway1,$global:DefGateway2,$global:DefGateway3,
    $global:PrimaryDNS,$global:PrimaryDNS1,$global:PrimaryDNS2,$global:PrimaryDNS3,
    $global:SecondDNS, $global:SecondDNS1, $global:SecondDNS2, $global:SecondDNS3)
    foreach ($Textbox in $textboxes){
        $Textbox.TextAlign = 'Center'
    }

    $Align = @($SystemPrefrencesBtn,$SystemBackupAndRestore,$NetworkSettings)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }

    $VarList = @($SystemPrefrencesBtn,$SystemBackupAndRestore,$NetworkSettings,$Titel,$Titel1,
    $global:SelectNetDrop,$Titel2,$global:IPAddres,$Titel3,$global:SubnetMask,$global:IPAddres1,
    $global:IPAddres2,$global:IPAddres3,$global:SubnetMask1,$global:SubnetMask2,$global:SubnetMask3,
    $global:DefGateway,$global:DefGateway1,$global:DefGateway2,$global:DefGateway3,$Titel4,
    $Titel5,$global:PrimaryDNS,$global:PrimaryDNS1,$global:PrimaryDNS2,$global:PrimaryDNS3,
    $global:SecondDNS, $global:SecondDNS1, $global:SecondDNS2, $global:SecondDNS3,$Titel6,
    $UpdateBtn,$global:checkBox)
    $global:ContentButtons = @($VarList)
    $global:OpenButton = $SystemPrefrencesBtn
}

function CreateUserSideBtn {
    CloseOpenButton
    
    $CreateUserSideBtn = Button -LocationY 130 -Text "Create New User"
    $CreateUserSideBtn.Add_Click({ $null })

    $DeleteUserSideBtn = Button -LocationY 165 -Text "Delete User"
    $DeleteUserSideBtn.Add_Click({ DeleteUserSideBtn })

    $ModifyUserSideBtn = Button -LocationY 200 -Text "Modify User"
    $ModifyUserSideBtn.Add_Click({ ModifyUserSideBtn })

    $ViewUserSideBtn = Button -LocationY 235 -Text "View all Users"
    $ViewUserSideBtn.Add_Click({ ViewUserSideBtn })

    $Titel = SimpleText -FontSize 16 -LocationX 243 -LocationY 135 -String "Create New User"
    
    $Titel1 = SimpleText -FontSize 11 -LocationX 245 -LocationY 185 -String "Full Name:" -Width 100
    $global:FullNameText = TextBox -FontSize 12 -Width 185 -Height 30 -LocationX 249 -LocationY 215
    
    $Titel2 = SimpleText -FontSize 11 -LocationX 245 -LocationY 258 -String "Username:" -Width 100
    $global:UsernameText = TextBox -FontSize 12 -Width 185 -Height 30 -LocationX 249 -LocationY 285
    
    $Titel3 = SimpleText -FontSize 11 -LocationX 465 -LocationY 187 -String "Password:"
    $global:PasswordText = TextBox -FontSize 12 -Width 185 -Height 30 -LocationX 469 -LocationY 215

    $Titel4 = SimpleText -FontSize 11 -LocationX 465 -LocationY 258 -String "Confirm Password:"
    $global:ConfirmUsernameText = TextBox -FontSize 12 -Width 185 -Height 30 -LocationX 469 -LocationY 285

    $Titel5 = SimpleText -FontSize 11 -LocationX 245 -LocationY 330 -String "User Type:"
    $global:SelectTypeDrop = DropdownMenu -FontSize 12 -Width 185 -Height 30 -LocationX 249 -LocationY 355 `
        -Arguments "Medical User", "Service Login User"

    $UpdateBtn = Button -Width 170 -Text "Proceed" -LocationX 250 -LocationY 641
    $UpdateBtn.Add_Click({
        if ($global:SelectTypeDrop.Text -eq "Service Login User"){
            CreateUser -FullName $global:FullNameText.Text `
                -Username $global:UsernameText.Text `
                -Password $global:PasswordText.Text `
                -ConfirmPassword $global:ConfirmUsernameText.Text
        }
        elseif ($global:SelectTypeDrop.Text -eq "Medical User") {
            
        }
        else {
            $MsgBoxError::Show("User Type not selected!", $maintaitel, "OK", "Warning")
        }
    })

    $Align = @($ViewUserSideBtn,$ModifyUserSideBtn,$DeleteUserSideBtn,$CreateUserSideBtn,$Titel,$Titel1)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }

    $VarList = @($ViewUserSideBtn,$ModifyUserSideBtn,$DeleteUserSideBtn,$CreateUserSideBtn,$Titel1,$Titel,
    $global:UsernameText,$Titel2,$global:FullNameText,$Titel3,$global:PasswordText,$Titel4,
    $global:ConfirmUsernameText,$UpdateBtn,$Titel5,$global:SelectTypeDrop)
    $global:ContentButtons = @($VarList)
    $global:OpenButton = $CreateUserSideBtn
}

function DeleteUserSideBtn {
    CloseOpenButton

    $CreateUserSideBtn = Button -LocationY 130 -Text "Create New User"
    $CreateUserSideBtn.Add_Click({ CreateUserSideBtn })

    $DeleteUserSideBtn = Button -LocationY 165 -Text "Delete User"
    $DeleteUserSideBtn.Add_Click({ $null })

    $ModifyUserSideBtn = Button -LocationY 200 -Text "Modify User"
    $ModifyUserSideBtn.Add_Click({ ModifyUserSideBtn })

    $ViewUserSideBtn = Button -LocationY 235 -Text "View all Users"
    $ViewUserSideBtn.Add_Click({ ViewUserSideBtn })

    $Align = @($CreateUserSideBtn,$DeleteUserSideBtn,$ModifyUserSideBtn,$ViewUserSideBtn)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }
    $VarList = @($CreateUserSideBtn,$DeleteUserSideBtn,$ModifyUserSideBtn,$ViewUserSideBtn)
    $global:ContentButtons = @($VarList)
    $global:OpenButton =$CreateUserSideBtn
}
function ModifyUserSideBtn {
    CloseOpenButton

    $CreateUserSideBtn = Button -LocationY 130 -Text "Create New User"
    $CreateUserSideBtn.Add_Click({ CreateUserSideBtn })

    $DeleteUserSideBtn = Button -LocationY 165 -Text "Delete User"
    $DeleteUserSideBtn.Add_Click({ DeleteUserSideBtn })

    $ModifyUserSideBtn = Button -LocationY 200 -Text "Modify User"
    $ModifyUserSideBtn.Add_Click({ $null })

    $ViewUserSideBtn = Button -LocationY 235 -Text "View all Users"
    $ViewUserSideBtn.Add_Click({ ViewUserSideBtn })

    $Align = @($CreateUserSideBtn,$DeleteUserSideBtn,$ModifyUserSideBtn,$ViewUserSideBtn)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }
    $VarList = @($CreateUserSideBtn,$DeleteUserSideBtn,$ModifyUserSideBtn,$ViewUserSideBtn)
    $global:ContentButtons = @($VarList)
    $global:OpenButton =$CreateUserSideBtn
}
function ViewUserSideBtn {
    CloseOpenButton

    $Titel = SimpleText -FontSize 16 -LocationX 243 -LocationY 135 -String "View All Users"

    $CreateUserSideBtn = Button -LocationY 130 -Text "Create New User"
    $CreateUserSideBtn.Add_Click({ CreateUserSideBtn })

    $DeleteUserSideBtn = Button -LocationY 165 -Text "Delete User"
    $DeleteUserSideBtn.Add_Click({ DeleteUserSideBtn })

    $ModifyUserSideBtn = Button -LocationY 200 -Text "Modify User"
    $ModifyUserSideBtn.Add_Click({ ModifyUserSideBtn })

    $ViewUserSideBtn = Button -LocationY 235 -Text "View all Users"
    $ViewUserSideBtn.Add_Click({ $null })

    $datagridview = New-Object System.Windows.Forms.DataGridView
    $datagridview.Location = New-Object System.Drawing.Point(248,195)
    $datagridview.Size = New-Object System.Drawing.Size(338,450)
    $datagridview.AllowUserToAddRows = $false
    $datagridview.AllowUserToDeleteRows = $false
    $datagridview.ReadOnly = $true
    $datagridview.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::AllCells
    $datagridview.DefaultCellStyle.Font = New-Object System.Drawing.Font("Segoe UI", 14)
    $datagridview.ColumnHeadersHeight = 40
    $datagridview.RowTemplate.Height = 30
    
    $form.Controls.Add($datagridview)
    $csvfile = Import-Csv -Path "D:\Site Variables\etc\credentials.csv" # TO D:\ 

    # Add columns to DataGridView
    $numberColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
    $numberColumn.Name = "Number"
    $numberColumn.HeaderText = "*"
    $numberColumn.HeaderCell.Style.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
    $datagridview.Columns.Add($numberColumn)

    foreach ($property in $csvfile[0].PSObject.Properties) {
        $columnName = $property.Name
        if ($columnName -ne "Password") {
            $column = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
            $column.Name = $columnName
            $column.HeaderText = $columnName
            $column.HeaderCell.Style.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
            $datagridview.Columns.Add($column)
        }
    }

    $rowNumber = 1
    foreach ($row in $csvfile) {
        $values = @()
        $values += $rowNumber
        foreach ($property in $row.PSObject.Properties) { `
            $propertyName = $property.Name
            if ($propertyName -ne "Password") {
                $values += $property.Value
            }
        }
        $datagridview.Rows.Add($values)
        $rowNumber++
    }

    $Align = @($ViewUserSideBtn,$ModifyUserSideBtn,$DeleteUserSideBtn,$CreateUserSideBtn,
    $Titel)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }
    $VarList = @($CreateUserSideBtn,$DeleteUserSideBtn,$ModifyUserSideBtn,
    $ViewUserSideBtn,$datagridview,$Titel)
    $global:ContentButtons = @($VarList)
    $global:OpenButton = $Titel
}

function SpesificSiteConfigBtn {
    CloseOpenButton
    
    [System.Windows.Forms.Cursor]::Current = 'WaitCursor' # Loading
    $SpesificSiteConfigBtn = Button -LocationY 130 -Text "Site Spesific Settings"
    $SpesificSiteConfigBtn.Add_Click({ $null })

    $CTScannersConfig = Button -LocationY 165 -Text "CT Scanners Settings"
    $CTScannersConfig.Add_Click({ CTScannersConfig })

    $DataBaseViewBtn = Button -LocationY 200 -Text "Database Viewer"
    $DataBaseViewBtn.Add_Click({ DataBaseViewBtn })

    $NewSiteConfig = Button -LocationY 235 -Text "New site Configurator"
    $NewSiteConfig.Add_Click({ NewSiteConfig })

    $Titel = SimpleText -FontSize 16 -LocationX 243 -LocationY 135 -String "Site Spesific Settings"

    $Titel1 = SimpleText -FontSize 11 -LocationX 245 -LocationY 185 -String "DevelopmentParamsConfig:"
    $global:DevParamConfGetText = TextBox -FontSize 12 -Width 450 -Height 30 -LocationX 469 -LocationY 215 -ReadOnly $True
    $global:DevParamConfText = TextBox -FontSize 12 -Width 185 -Height 30 -LocationX 954 -LocationY 215
    $global:DevParamConfDrop = DropdownMenu -Width 185 -Height 30 -LocationX 249 -LocationY 215 -Arguments @(
        "SupportedNeedles","SupportedCTScanners")
    $global:DevParamConfDrop.add_SelectedIndexChanged({
        Update-ReadOnlyTextBox -DropDownMenu $global:DevParamConfDrop `
            -Path "C:\X Robotics\X_app\Config\Common\" `
            -File "DevelopmentParamsConfig.xml" `
            -ReadOnlyTextBox $global:DevParamConfGetText
        }    
    )

    $Titel2 = SimpleText -FontSize 11 -LocationX 245 -LocationY 258 -String "DataCollectionConfig:"
    $global:DataCollectConfGetText = TextBox -FontSize 12 -Width 450 -Height 30 -LocationX 469 -LocationY 285 -ReadOnly $True
    $global:DataCollectConfText = TextBox -FontSize 12 -Width 185 -Height 30 -LocationX 954 -LocationY 285
    $global:DataCollectConfDrop = DropdownMenu -FontSize 12 -Width 185 -Height 30 -LocationX 249 -LocationY 285 -Arguments @(
        "Organs", "TargetTypes", "ClinicalProcedures", "Physicians", "Technologists")
    $global:DataCollectConfDrop.add_SelectedIndexChanged({
        Update-ReadOnlyTextBox -DropDownMenu $global:DataCollectConfDrop `
            -Path "C:\X Robotics\X_app\Config\Workstation\" `
            -File "DataCollectionConfig.xml" `
            -ReadOnlyTextBox $global:DataCollectConfGetText
        }
    )
    
    $Titel3 = SimpleText -FontSize 11 -LocationX 245 -LocationY 331 -String "Needles Alias Config:"
    $global:NeedlesConfigGetText = TextBox -FontSize 12 -Width 450 -Height 30 -LocationX 469 -LocationY 357 -ReadOnly $True
    $global:NeedlesConfigGetText.Text = "N / A"
    $global:NeedlesConfigText = TextBox -FontSize 12 -Width 185 -Height 30 -LocationX 954 -LocationY 357
    $Path2 = "C:\X Robotics\X_app\Config\Common\Needles"
    $global:NeedlesConfigDrop = DropdownMenuContant -Width 185 -Height 30 -LocationX 249 -LocationY 357 -DirectoryPaths $Path2
 

    # Create the checkbox with the specified functions
    $global:checkBox = New-Checkbox -Text "Overwrite existing data" -LocationX 250 -LocationY 605 -Checked $false

    # Create the button
    $UpdateBtn = Button -Width 170 -Text "Proceed" -LocationX 250 -LocationY 641
    $UpdateBtn.Add_Click({
        if (-not $global:checkBox.Checked) {
            $Path = "C:\X Robotics\X_app\Config"
            UpdateXML -FilePath "$Path\Workstation\DataCollectionConfig.xml" -Node $global:DataCollectConfDrop.Text -NodeContent $global:DataCollectConfText.Text
            UpdateXML -FilePath "$Path\Common\DevelopmentParamsConfig.xml" -Node $global:DevParamConfDrop.Text -NodeContent $global:DevParamConfText.Text
        }
        else {
            
        }
    })

    $Align = @($SpesificSiteConfigBtn,$CTScannersConfig,$DataBaseViewBtn,$NewSiteConfig)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }
    $VarList = @($SpesificSiteConfigBtn,$CTScannersConfig,$Titel,$Titel1,$DevParamConfDrop,
    $DevParamConfText,$Titel2,$global:DataCollectConfDrop,$global:DataCollectConfText,$checkbox,
    $UpdateBtn,$DataBaseViewBtn,$global:DevParamConfGetText,$global:DataCollectConfGetText,
    $global:VoidGetText,$Titel3,$global:NeedlesConfigGetText,$global:NeedlesConfigText,
    $global:NeedlesConfigDrop,$NewSiteConfig)
    $global:ContentButtons = @($VarList)
    $global:OpenButton = $SpesificSiteConfigBtn
}

function CTScannersConfig {
    CloseOpenButton

    [System.Windows.Forms.Cursor]::Current = 'WaitCursor' # Loading
    $SpesificSiteConfigBtn = Button -LocationY 130 -Text "Site Spesific Settings"
    $SpesificSiteConfigBtn.Add_Click({ SpesificSiteConfigBtn })

    $CTScannersConfig = Button -LocationY 165 -Text "CT Scanners Settings"
    $CTScannersConfig.Add_Click({ $null })

    $DataBaseViewBtn = Button -LocationY 200 -Text "Database Viewer"
    $DataBaseViewBtn.Add_Click({ DataBaseViewBtn })

    $NewSiteConfig = Button -LocationY 235 -Text "New site Configurator"
    $NewSiteConfig.Add_Click({ NewSiteConfig })

    $Titel = SimpleText -FontSize 16 -LocationX 243 -LocationY 135 -String "CT Scanners Settings"

    $Titel2 = SimpleText -FontSize 11 -LocationX 245 -LocationY 263 -String "X App AE Title:"
    $global:XStationAETitle = TextBox -FontSize 12 -Width 185 -Height 30 -LocationX 249 -LocationY 290
    
    $Titel3 = SimpleText -FontSize 11 -LocationX 467 -LocationY 263 -String "X app IP Address:"    
    $global:XIPText = TextBox -FontSize 12 -Width 185 -Height 30 -LocationX 469 -LocationY 290
    
    $Titel4 = SimpleText -FontSize 11 -LocationX 245 -LocationY 330 -String "X App Subnet Mask:"
    $global:XNetMaskText = TextBox -FontSize 12 -Width 185 -Height 30 -LocationX 249 -LocationY 355
    
    $Titel5 = SimpleText -FontSize 11 -LocationX 467 -LocationY 330 -String "X App Gateway:"
    $global:XGatewayText = TextBox -FontSize 12 -Width 185 -Height 30 -LocationX 469 -LocationY 356

    $Titel6 = SimpleText -FontSize 11 -LocationX 245 -LocationY 435 -String "CT Scanner AE Title:"
    $global:CTAETitleText = TextBox -FontSize 12 -Width 185 -Height 30 -LocationX 249 -LocationY 460
    
    $Titel7 = SimpleText -FontSize 11 -LocationX 467 -LocationY 435 -String "CT Scanner IP Address:"
    $global:CTIPAddressText = TextBox -FontSize 12 -Width 185 -Height 30 -LocationX 469 -LocationY 461

    $Titel8 = SimpleText -FontSize 11 -LocationX 245 -LocationY 536 -String "CT Scanner Delay (Ms):"
    $global:CTScanDelayText = TextBox -FontSize 12 -Width 185 -Height 30 -LocationX 249 -LocationY 561
    
    $Titel9 = SimpleText -FontSize 11 -LocationX 467 -LocationY 535 -String "CT Connectivity Port:"
    $global:CTPortText = TextBox -FontSize 12 -Width 185 -Height 30 -LocationX 469 -LocationY 562

    $Titel10 = SimpleText -FontSize 11 -LocationX 245 -LocationY 185 -String "Select CT Database:"
    $Path = "C:\X Robotics\X_app\Config\Workstation\CTScanners\"
    $global:SelectCTDrop = DropdownMenuContant -Width 230 -Height 30 -LocationX 249 -LocationY 215 -DirectoryPath $Path -AdditionalString "New CT Database"
    $global:NewFileNameText = TextBox -Visable $False -FontSize 12 -Width 230 -Height 30 -LocationX 515 -LocationY 215
    $global:NewFileNameText.add_Gotfocus({$global:NewFileNameText.Clear()})
    $global:NewFileNameText.Text = "Enter New Name"

    $global:UpdateBtn = Button -Width 170 -Text "Proceed" -LocationX 250 -LocationY 641
    
    $global:SelectCTDrop.add_SelectedIndexChanged({
        param($sender, $e)
        $selectedItem = $sender.SelectedItem
        $textBoxVisible = $selectedItem -eq "New CT Database"
        $global:Form.Invoke([System.Action]{
            $global:NewFileNameText.Visible = $textBoxVisible
    
            if ($textBoxVisible) {
                # Operation to perform when the textbox is visible
                Write-Host "Perform operation A." -ForegroundColor "Green"
            } else {
                # Operation to perform when the textbox is not visible
                Write-Host "Perform operation B." -ForegroundColor "Cyan"
            }
        })
    })

    $global:UpdateBtn.Add_Click({
        if ($global:NewFileNameText.Visible) {
            FuncA
        } else {
            FuncB
        }
    })

    $Align = @($SpesificSiteConfigBtn,$CTScannersConfig,$DataBaseViewBtn,$NewSiteConfig,$NewSiteConfig)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }
    $VarList = @($SpesificSiteConfigBtn,$CTScannersConfig,$Titel,$global:SelectCTDrop,
    $Titel9,$Titel8,$Titel10,$global:NewFileNameText,$Titel2,$Titel3,$Titel4,
    $Titel5,$Titel6,$Titel7,$global:CTScannerAETitle,$global:XStationAETitle,
    $global:XIPText,$global:XNetMaskText,$global:XGatewayText,$global:CTAETitleText,
    $global:CTIPAddressText,$UpdateBtn,$global:CTScanDelayText,$global:CTPortText,
    $DataBaseViewBtn,$NewSiteConfig)
    
    $global:ContentButtons = @($VarList)
    $global:OpenButton = $SpesificSiteConfigBtn
}

function DataBaseViewBtn {
    CloseOpenButton

    [System.Windows.Forms.Cursor]::Current = 'WaitCursor' # Loading
    $SpesificSiteConfigBtn = Button -LocationY 130 -Text "Site Spesific Settings"
    $SpesificSiteConfigBtn.Add_Click({ SpesificSiteConfigBtn })

    $CTScannersConfig = Button -LocationY 165 -Text "CT Scanners Settings"
    $CTScannersConfig.Add_Click({ CTScannersConfig })

    $DataBaseViewBtn = Button -LocationY 200 -Text "Database Viewer"
    $DataBaseViewBtn.Add_Click({ $null })

    $NewSiteConfig = Button -LocationY 235 -Text "New site Configurator"
    $NewSiteConfig.Add_Click({ NewSiteConfig })

    $Titel = SimpleText -FontSize 16 -LocationX 243 -LocationY 135 -String "Database Viewer"
    $Titel1 = SimpleText -FontSize 11 -LocationX 245 -LocationY 185 -String "Directory:"
    
    # Handle the selection change event of $global:DirectoryDrop
    $global:DirectoryDrop = DropdownMenu -Width 250 -Height 30 -LocationX 249 -LocationY 215 -Arguments "Common",
    "CoreEngine","RespirationSensor","Workstation","Common\Needles","Common\Robots","Workstation\CTScanners"
    $global:DirectoryDrop.Add_SelectedIndexChanged({
        $Path = [string]::Concat("C:\X Robotics\X_app\Config\",$($global:DirectoryDrop.SelectedItem),"\")
        $global:DatabaseDrop.Items.Clear()  # Clear previous items
        if (Test-Path -Path $Path -PathType Container) {
            $Files = Get-ChildItem -Path $Path -File
            foreach ($File in $Files) {
                [void]$global:DatabaseDrop.Items.Add($File.Name)
            }
        }
    })
    
    $Titel2 = SimpleText -FontSize 11 -LocationX 245 -LocationY 258 -String "Database:"
    $global:DatabaseDrop = DropdownMenuContant -Width 250 -Height 30 -LocationX 249 -LocationY 285 -DirectoryPaths $Path 
    
    #$Titel3 = SimpleText -FontSize 12 -LocationX 245 -LocationY 330 -String "Node (Optional):"
    #$global:NodeDrop = DropdownMenu -FontSize 12 -Width 250 -Height 30 -LocationX 249 -LocationY 355 -Arguments "1", "2", "3"

    $global:RefreshBtn = Button -Width 170 -Text "Refresh" -LocationX 250 -LocationY 641
    $global:RefreshBtn.Add_Click({ ViweXML -Directory $global:DirectoryDrop.Text -File $global:DatabaseDrop.Text })

    $Align = @($SpesificSiteConfigBtn,$CTScannersConfig,$DataBaseViewBtn,$NewSiteConfig)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }
    $VarList = @($Titel,$Titel1,$Titel2,$Titel3,$global:DirectoryDrop,$global:DatabaseDrop,
    $global:NodeDrop,$global:RefreshBtn,$SpesificSiteConfigBtn,$CTScannersConfig,$DataBaseViewBtn,
    $NewSiteConfig)
    $global:ContentButtons = @($VarList)
    $global:OpenButton = $SpesificSiteConfigBtn
}

function NewSiteConfig {
    CloseOpenButton

    $SpesificSiteConfigBtn = Button -LocationY 130 -Text "Site Spesific Settings"
    $SpesificSiteConfigBtn.Add_Click({ SpesificSiteConfigBtn })

    $CTScannersConfig = Button -LocationY 165 -Text "CT Scanners Settings"
    $CTScannersConfig.Add_Click({ CTScannersConfig })

    $DataBaseViewBtn = Button -LocationY 200 -Text "Database Viewer"
    $DataBaseViewBtn.Add_Click({ DataBaseViewBtn })

    $NewSiteConfig = Button -LocationY 235 -Text "New site Configurator"
    $NewSiteConfig.Add_Click({ $null })
    
    $Titel = SimpleText -FontSize 16 -LocationX 243 -LocationY 135 -String "New site Configurator"

    $Align = @($SpesificSiteConfigBtn,$CTScannersConfig,$DataBaseViewBtn,$NewSiteConfig)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }
    $VarList = @($SpesificSiteConfigBtn,$CTScannersConfig,$DataBaseViewBtn,$NewSiteConfig,$Titel)
    $global:ContentButtons = @($VarList)
    $global:OpenButton = $SpesificSiteConfigBtn
}

function SystemAndSecurityBtn {
    CloseOpenButton

    [System.Windows.Forms.Cursor]::Current = 'WaitCursor' # Loading
    $global:GetSysVersion = Get-WindowsInformation
    $global:ShowSysVersion = SimpleText -FontSize 13 -LocationX 243 -LocationY 175 -Width 400 -Height 145 -String $global:GetSysVersion

    $global:GetDefenderInfo = GetWindowsDefenderInfo
    $global:ShowDefenderInfo = SimpleText -FontSize 13 -LocationX 243 -LocationY 335 -Width 400 -Height 200 -String $global:GetDefenderInfo

    $SystemAndSecurityBtn = Button -LocationY 130 -Text "System and Security"
    $SystemAndSecurityBtn.Add_Click({ $null })

    $ApplicationBtn = Button -LocationY 165 -Text "Windows Applications"
    $ApplicationBtn.Add_Click({ ApplicationBtn })

    $XApplicationsBtn = Button -LocationY 200 -Text "X Applications"
    $XApplicationsBtn.Add_Click({ XApplicationsBtn })

    $ControllersBtn = Button -LocationY 235 -Text "Controllers and Drivers"
    $ControllersBtn.Add_Click({ ControllersBtn })

    $WindowsUpdateHistory = Button -LocationY 270 -Text "Update History"
    $WindowsUpdateHistory.Add_Click({ WindowsUpdateHistory })

    $Titel = SimpleText -FontSize 16 -LocationX 243 -LocationY 135 -Width 355 -String "System and Security"

    $Align = @($SystemAndSecurityBtn,$ApplicationBtn,$XApplicationsBtn,$ControllersBtn,$WindowsUpdateHistory)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }

    $VarList = @($SystemAndSecurityBtn,$ApplicationBtn,$XApplicationsBtn,$ControllersBtn,$WindowsUpdateHistory,$Titel,
    $global:ShowSysVersion,$global:GetSysVersion,$global:ShowDefenderInfo,$global:GetDefenderInfo)
    $global:ContentButtons = @($VarList)
    $global:OpenButton = $SystemAndSecurityBtn
}

function ApplicationBtn {
    CloseOpenButton

    $SystemAndSecurityBtn = Button -LocationY 130 -Text "System and Security"
    $SystemAndSecurityBtn.Add_Click({ SystemAndSecurityBtn })

    $ApplicationBtn = Button -LocationY 165 -Text "Windows Applications"
    $ApplicationBtn.Add_Click({ $null })

    $XApplicationsBtn = Button -LocationY 200 -Text "X Applications"
    $XApplicationsBtn.Add_Click({ XApplicationsBtn })

    $ControllersBtn = Button -LocationY 235 -Text "Controllers and Drivers"
    $ControllersBtn.Add_Click({ ControllersBtn })

    $WindowsUpdateHistory = Button -LocationY 270 -Text "Update History"
    $WindowsUpdateHistory.Add_Click({ WindowsUpdateHistory })

    $Titel = SimpleText -FontSize 16 -LocationX 243 -LocationY 135 -Width 355 -String "Windows Applications"

    $Align = @($SystemAndSecurityBtn,$ApplicationBtn,$XApplicationsBtn,$ControllersBtn,$WindowsUpdateHistory)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }

    $VarList = @($SystemAndSecurityBtn,$ApplicationBtn,$XApplicationsBtn,$ControllersBtn,$WindowsUpdateHistory,$Titel)
    $global:ContentButtons = @($VarList)
    $global:OpenButton = $SystemAndSecurityBtn
}

function XApplicationsBtn {
    CloseOpenButton

    $SystemAndSecurityBtn = Button -LocationY 130 -Text "System and Security"
    $SystemAndSecurityBtn.Add_Click({ SystemAndSecurityBtn })

    $ApplicationBtn = Button -LocationY 165 -Text "Windows Applications"
    $ApplicationBtn.Add_Click({ ApplicationBtn })

    $XApplicationsBtn = Button -LocationY 200 -Text "X Applications"
    $XApplicationsBtn.Add_Click({ $null })

    $ControllersBtn = Button -LocationY 235 -Text "Controllers and Drivers"
    $ControllersBtn.Add_Click({ ControllersBtn })

    $WindowsUpdateHistory = Button -LocationY 270 -Text "Update History"
    $WindowsUpdateHistory.Add_Click({ WindowsUpdateHistory })

    $Titel = SimpleText -FontSize 16 -LocationX 243 -LocationY 135 -Width 355 -String "X Robotics Applications"

    $Align = @($SystemAndSecurityBtn,$ApplicationBtn,$XApplicationsBtn,$ControllersBtn,$WindowsUpdateHistory)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }

    $VarList = @($SystemAndSecurityBtn,$ApplicationBtn,$XApplicationsBtn,$ControllersBtn,$WindowsUpdateHistory,$Titel)
    $global:ContentButtons = @($VarList)
    $global:OpenButton = $SystemAndSecurityBtn
}

function ControllersBtn {
    CloseOpenButton

    $SystemAndSecurityBtn = Button -LocationY 130 -Text "System and Security"
    $SystemAndSecurityBtn.Add_Click({ SystemAndSecurityBtn })

    $ApplicationBtn = Button -LocationY 165 -Text "Windows Applications"
    $ApplicationBtn.Add_Click({ ApplicationBtn })

    $XApplicationsBtn = Button -LocationY 200 -Text "X Applications"
    $XApplicationsBtn.Add_Click({ XApplicationsBtn })

    $ControllersBtn = Button -LocationY 235 -Text "Controllers and Drivers"
    $ControllersBtn.Add_Click({ $null })

    $WindowsUpdateHistory = Button -LocationY 270 -Text "Update History"
    $WindowsUpdateHistory.Add_Click({ WindowsUpdateHistory })

    $Titel = SimpleText -FontSize 16 -LocationX 243 -LocationY 135 -Width 355 -String "Controllers and Drivers"

    $Align = @($SystemAndSecurityBtn,$ApplicationBtn,$XApplicationsBtn,$ControllersBtn,$WindowsUpdateHistory)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }

    $VarList = @($SystemAndSecurityBtn,$ApplicationBtn,$XApplicationsBtn,$ControllersBtn,$WindowsUpdateHistory,$Titel)
    $global:ContentButtons = @($VarList)
    $global:OpenButton = $SystemAndSecurityBtn
}

function WindowsUpdateHistory {
    CloseOpenButton
    
    [System.Windows.Forms.Cursor]::Current = 'WaitCursor' # Loading
    $global:GetUPdates = Get-LastWindowsUpdates
    $global:ShowUPdates = SimpleText -FontSize 13 -LocationX 243 -LocationY 175 -Width 400 -Height 600 -String $global:GetUPdates

    $SystemAndSecurityBtn = Button -LocationY 130 -Text "System and Security"
    $SystemAndSecurityBtn.Add_Click({ SystemAndSecurityBtn })

    $ApplicationBtn = Button -LocationY 165 -Text "Windows Applications"
    $ApplicationBtn.Add_Click({ ApplicationBtn })

    $XApplicationsBtn = Button -LocationY 200 -Text "X Applications"
    $XApplicationsBtn.Add_Click({ XApplicationsBtn })

    $ControllersBtn = Button -LocationY 235 -Text "Controllers and Drivers"
    $ControllersBtn.Add_Click({ ControllersBtn })

    $WindowsUpdateHistory = Button -LocationY 270 -Text "Update History"
    $WindowsUpdateHistory.Add_Click({ $null })

    $Titel = SimpleText -FontSize 16 -LocationX 243 -LocationY 135 -Width 355 -String "OS and Security Update History"

    $Align = @($SystemAndSecurityBtn,$ApplicationBtn,$XApplicationsBtn,$ControllersBtn,$WindowsUpdateHistory)
    foreach ($Text in $Align){
        $Text.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    }

    $VarList = @($SystemAndSecurityBtn,$ApplicationBtn,$XApplicationsBtn,$ControllersBtn,$WindowsUpdateHistory,$Titel,$global:ShowUPdates)
    $global:ContentButtons = @($VarList)
    $global:OpenButton = $global:ShowUPdates
}

#-------------------------------------------------------------[Show form]-----------------------------------------------------------

function closeForm(){$global:Form.close()}

$global:Form.ShowDialog() | Out-Null

