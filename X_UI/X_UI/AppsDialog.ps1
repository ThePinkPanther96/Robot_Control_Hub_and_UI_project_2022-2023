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

$SecondForm = New-Object system.Windows.Forms.Form
$SecondForm.ProcessWindowStyle.Hidden
$SecondForm.StartPosition = 'CenterScreen'
$secondForm.FormBorderStyle = 'None'
$SecondForm.ClientSize = '400,350'
$SecondForm.BackColor = "#FFFFFF"
$SecondForm.MaximizeBox = $False
$SecondForm.ShowInTaskbar = $false
$SecondForm.MaximizeBox = $false
$SecondForm.MinimizeBox = $false

$Image = [System.Drawing.Image]::FromFile("$scriptDirectory\Logos\AppsMenu.png") # Edit
$SecondForm.BackgroundImage = $Image
# Enable double buffering
$SecondForm.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance).SetValue($SecondForm, $true, $null)

#------------------------------------------------------------------[Controls]---------------------------------------------------------------------
function Button () {
    param (
        [string]$Text,[string]$ForeColor = "Black",[string]$BackColor = "#333333",
        [int]$FontSize = '13',[int]$Width = 90,[int]$Height = 90,
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
    
    $SecondForm.Controls.Add($Btn)
    return $Btn
}

function SimpleText () {
    param (
        [string]$String,[int]$FontSize = 10,
        [string]$ForeColor = "White",[string]$BackColor = "Transparent",
        [int]$Width = 180 ,[int]$Height = 25,[int]$LocationX,[int]$LocationY,
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

    $SecondForm.Controls.Add($SimpleText)
    return $SimpleText
}

#-------------------------------------------------------------[Event Handlers]-----------------------------------------------------------

$ExitBtn = Button -LocationX 362 -LocationY 10 -Width 27 -Height 27
$ExitBtnImage = [System.Drawing.Image]::FromFile("$scriptDirectory\Icons\CloseMenuBtn.png")
$ExitBtn.Image = $ExitBtnImage
$ExitBtn.Add_Click({ CloseForm })

$SimulationBtn = Button -LocationX 59 -LocationY 57 -Width 90 -Height 90
$SimulationBtnImage = [System.Drawing.Image]::FromFile("$scriptDirectory\Icons\SimulationIcon.png")
$SimulationBtn.Image = $SimulationBtnImage
$SimulationBtn.Add_Click({ RunSimulation })

$ExportBtn = Button -LocationX 258 -LocationY 55 -Width 102 -Height 90
$ExportBtnImage = [System.Drawing.Image]::FromFile("$scriptDirectory\Icons\ExportIcon1.png")
$ExportBtn.Image = $ExportBtnImage
$ExportBtn.Add_Click({ RunExport })

$CalibrationBtn = Button -LocationX 59 -LocationY 210 -Width 90 -Height 90
$CalibrationBtnImage = [System.Drawing.Image]::FromFile("$scriptDirectory\Icons\CalibrationIcon.png")
$CalibrationBtn.Image = $CalibrationBtnImage
$CalibrationBtn.Add_Click({ RunCalibration })

$VideoBtn = Button -LocationX 250 -LocationY 210 -Width 90 -Height 90
$VideoBtnBtnImage = [System.Drawing.Image]::FromFile("$scriptDirectory\Icons\VideoIcon.png")
$VideoBtn.Image = $VideoBtnBtnImage
$VideoBtn.Add_Click({ OpenVideo })

$ExportText = SimpleText -LocationX 230 -LocationY 155 -String "Export Procedures Data"

$SimulationText = SimpleText -LocationX 58 -LocationY 155 -String "Host Simulator"

$CalibrationText = SimpleText -LocationX 70 -LocationY 310 -String "Calibration" -Width 72

$VideoText = SimpleText -LocationX 231 -LocationY 310 -String "Breathing Instructions"

#-------------------------------------------------------------[Show form]-----------------------------------------------------------

function closeForm(){$SecondForm.close()}

[void]$SecondForm.ShowDialog()
