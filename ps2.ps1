function Get-Screen
{
Add-Type -AssemblyName System.Windows.Forms
Add-type -AssemblyName System.Drawing
[Windows.Forms.Sendkeys]::SendWait("{PrtSc}")  
start-sleep -Milliseconds 250
$bitmap = [Windows.Forms.Clipboard]::GetImage()  

$screenCapturePathBase = "c:\temp\ScreenCapture\file"

$c = 0
while (Test-Path "$screenCapturePathBase$c.bmp") {
	$c++
}

$File = "$screenCapturePathBase$c.bmp"

# Save to file
$bitmap.Save($File) 
Write-Output "Screenshot saved to:"
Write-Output $File

[Windows.Forms.Clipboard]::Clear()
}

Get-Screen
