# Get Path
$scriptDirectory = Split-Path $MyInvocation.MyCommand.Path
# Set working directory to the script directory
Set-Location $scriptDirectory

. "$scriptDirectory\X_UI_Logic.ps1"

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

# Call Disable Keys
#LockKeys

# Get User
GetUser

#------------------------------------------------------------[Main Menu]---------------------------------------------------------
# Create a new form

$Form = New-Object system.Windows.Forms.Form
$Form.WindowState = 'Maximized'
$Form.FormBorderStyle = 'None'
$Form.StartPosition = 'CenterScreen'
$Form.Form.ProcessWindowStyle.Hidden
$Form.MaximizeBox = $False
$Form.MaximizeBox = $false
$Form.ShowInTaskbar = $false
$Image = [System.Drawing.Image]::FromFile("$scriptDirectory\Logos\Background.png") # Edit
$Form.BackgroundImage = $Image
$Form.BackgroundImageLayout = "Center"

$Form.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance).SetValue($Form, $true, $null)

# Error message
#$MsgBoxError = [System.Windows.Forms.MessageBox]
#[System.Windows.Forms.Application]::EnableVisualStyles()

#------------------------------------------------------------------[Controls]---------------------------------------------------------------------
function Button () {
    param (
        [string]$Text,[string]$ForeColor = "Black",[string]$BackColor = "#333333",
        [int]$FontSize = '13',[int]$Width = 220,[int]$Height = 250,
        [int]$LocationX,[int]$LocationY
    )
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.FlatAppearance.BorderSize = 0
    $Btn.Text = $Text
    $Btn.Width = $Width
    $Btn.Height = $Height
    $Btn.ForeColor = $ForeColor
    $Btn.BackColor = $BackColor
    $Btn.Location = New-Object System.Drawing.Point($LocationX, $LocationY)
    $Btn.Font = "Microsoft Sans Serif,$FontSize"
    $Btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    
    $Form.Controls.Add($Btn)
    return $Btn
}

function SimpleText () {
    param (
        [string]$String,[string]$FontSize,
        [string]$ForeColor = "#FFFFFF",[string]$BackColor = "Transparent",
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

    $Form.Controls.Add($SimpleText)
    return $SimpleText
}

#-------------------------------------------------------------[Event Hndlers]-----------------------------------------------------------

$Info = SimpleText -FontSize 7.5 -LocationX 1660 -LocationY 1062 -Width 260 -String "Copyright © Gal R 2023-2024 | UI v1.0"

$XBtn = Button -LocationX 850 -LocationY 500 -FontSize 10
$XImage = [System.Drawing.Image]::FromFile("$scriptDirectory\Logos\XNew.ico")
$XBtn.Image = $XImage
$XBtn.Add_Click({ RunX })

$ShutdownBtn = Button -Width 50 -Height 50 -LocationX 5 -LocationY 1025
$ShutdownBtnImage = [System.Drawing.Image]::FromFile("$scriptDirectory\Icons\PowerBtnIcon.png")
$ShutdownBtn.Image = $ShutdownBtnImage
$ShutdownBtn.Add_Click({ ShutdownPC })

$RebootBtn = Button -Width 50 -Height 50 -LocationX 65 -LocationY 1025
$RebootBtnImage = [System.Drawing.Image]::FromFile("$scriptDirectory\Icons\RebootBtnIcon.png")
$RebootBtn.Image = $RebootBtnImage
$RebootBtn.Add_Click({ RebootComputer })

$ChangeUsertBtn = Button -Width 50 -Height 50 -LocationX 125 -LocationY 1025
$ChangeUsertBtnImage = [System.Drawing.Image]::FromFile("$scriptDirectory\Icons\ChangeUserBtnIcon.png")
$ChangeUsertBtn.Image = $ChangeUsertBtnImage
$ChangeUsertBtn.Add_Click({ ChangeUser })

$AppsBtn = Button -Width 50 -Height 50 -LocationX 185 -LocationY 1025
$AppsBtnImage = [System.Drawing.Image]::FromFile("$scriptDirectory\Icons\AppsBtn.png")
$AppsBtn.Image = $AppsBtnImage
$AppsBtn.Add_Click({ OpenAppsDialog })

$KeyboardBtn = Button -Width 51 -Height 50 -LocationX 250 -LocationY 1025
$KeyboardBtnImage = [System.Drawing.Image]::FromFile("$scriptDirectory\Icons\KeyboardIcon1.png")
$KeyboardBtn.Image = $KeyboardBtnImage
$KeyboardBtn.Add_Click({ OnScreenKeyboard })

#-------------------------------------------------------------[Show form]-----------------------------------------------------------

function closeForm(){$Form.close()}

$Form.ShowDialog() | Out-Null