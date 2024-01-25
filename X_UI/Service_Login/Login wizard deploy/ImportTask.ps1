$xmlPath = "C:\Path\to\Task.xml"
$taskName = "Service Login"

# Import the scheduled task from XML using schtasks.exe
$importCommand = "schtasks.exe /Create /Xml `"$xmlPath`" /TN `"$taskName`""
Invoke-Expression -Command $importCommand

# Verify the task details
Get-ScheduledTask -TaskPath "\" -TaskName $taskName
