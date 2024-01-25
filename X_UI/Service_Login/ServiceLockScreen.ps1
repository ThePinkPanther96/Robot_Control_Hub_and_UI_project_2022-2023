# Get Path
$scriptDirectory = Split-Path $MyInvocation.MyCommand.Path
# Set working directory to the script directory
Set-Location $scriptDirectory

# Init
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Get path
. "$scriptDirectory\LoginLogic.ps1"

# Error message
$MsgBoxError = [System.Windows.Forms.MessageBox]

#---------------------------------------------------------[Forms Assembly]----------------------------------------------------------------

# First form
$firstForm = New-Object System.Windows.Forms.Form
$firstForm.TransparencyKey = $firstForm.BackColor
$firstForm.FormBorderStyle = 'Fixed3D'
$firstForm.BackColor = 'Gray'
$firstForm.WindowState = 'Maximized'
$firstForm.FormBorderStyle = 'None'
$firstForm.Opacity = 0.30
$firstForm.ShowInTaskbar = $true # To Edit
# Enable double buffering
$firstForm.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance).SetValue($firstForm, $true, $null)

# Second form
$secondForm = New-Object System.Windows.Forms.Form
$Image = [System.Drawing.Image]::FromFile("C:\X_UI\Service_Login\ServiceLogin.png")
$secondForm.BackgroundImage = $Image
$secondForm.Size = New-Object System.Drawing.Size(500,240)
$secondForm.TransparencyKey = $secondForm.BackColor
$secondForm.FormBorderStyle = 'Fixed3D'
$secondForm.StartPosition = 'CenterScreen'
$secondForm.FormBorderStyle = 'None'
$secondForm.MaximizeBox = $false
$secondForm.MinimizeBox = $false
$secondForm.ControlBox = $false
$firstForm.ShowInTaskbar = $true # To Edit
# Enable double buffering
$secondForm.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance).SetValue($secondForm, $true, $null)

# Call Disable Keys
StartLockKeys

#-------------------------------------------------------[Controls (Second Form]----------------------------------------------------------------
function Button () {
    param (
        [string]$Text,[string]$ForeColor = "Black",[string]$BackColor = "#D9D9D9",
        [int]$FontSize = '13',[int]$Width = 200,[int]$Height = 35,
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
    
    $secondForm.Controls.Add($Btn)
    return $Btn
}

function TextBox () {
    param (
        [string]$FontSize,
        [int]$Width = 210,[int]$Height = 30,[int]$LocationX,[int]$LocationY,
        [bool]$Visable = $True, [bool]$Multiline = $False
    )
    $TextBox = New-Object system.Windows.Forms.TextBox
    $TextBox.width = $Width
    $TextBox.height = $Height
    $TextBox.location = New-Object System.Drawing.Point($LocationX, $LocationY)
    $TextBox.Font = "Microsoft Sans Serif,$FontSize"
    $TextBox.Visible = $Visable
    $TextBox.multiline = $Multiline
    #$TextBox.add_Gotfocus({$TextBox.Clear()})

    $secondForm.Controls.Add($TextBox)
    return $TextBox
}

function SimpleText () {
    param (
        [string]$String,[string]$FontSize,
        [string]$ForeColor = "#000000",[string]$BackColor = "Transparent",
        [int]$Width = 200,[int]$Height = 25,[int]$LocationX,[int]$LocationY,
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

    $secondForm.Controls.Add($SimpleText)
    return $SimpleText
}

#----------------------------------------------------------[Logic]----------------------------------------------------------------

$UsernameText = TextBox -FontSize 13 -LocationX 27 -LocationY 125
$UsernameText.add_Gotfocus({$UsernameText.Clear()})

$PasswordText = TextBox -FontSize 13 -LocationX 263 -LocationY 125
$PasswordText.add_Gotfocus({$PasswordText.Clear()})
$PasswordText.ForeColor = "#ffffff"

$Username = SimpleText -FontSize 13 -LocationX 27 -LocationY 100 -String "Username"

$Password = SimpleText -FontSize 13 -LocationX 263 -LocationY 100 -String "Password"

$Button = Button -LocationX 175 -LocationY 190 -Width 150 -Text "Login"
$Button.Add_Click({ Login -Username $UsernameText.Text -Password $PasswordText.Text })
$secondForm.AcceptButton = $Button #Accepts button as Enter

function Login {
    param(
        [string]$Username,
        [string]$Password
    )
    [System.Windows.Forms.Cursor]::Current = 'WaitCursor' # Loading
    LoginLogger "[FUNCTION][ServiceLogin] - User Prassed Login"
    $Path = "$SiteVarsPath\etc\credentials.csv"
    try {
        if(Test-Path -Path $Path){
            LoginLogger "[FUNCTION][ServiceLogin] - Database path is OK"
            GetUserCredentials -Username $Username -Password $Password
        }
        else {
            LoginLogger "[ERROR]Service[Login] - System Error: $_"
            $MsgBoxError::Show("System Error! Could not connect to database.", $maintaitel, "OK", "Error")
        }  
    }
    catch {
        LoginLogger "[ERROR][ServiceLogin] - System Error: $_"
        $MsgBoxError::Show("System Error! Problem with password authentication.", $maintaitel, "OK", "Error")
    }
    
}

#-------------------------------------------------------[Show Forms]----------------------------------------------------------------

# Show the first form
$firstForm.Show()

# Show the second form on top of the first form
$secondForm.ShowDialog($firstForm)

# Dispose the forms after closing
$firstForm.Dispose()
$secondForm.Dispose()
