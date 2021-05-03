function Get-Screen
{
	$screenCapturePathBase = "c:\temp\ScreenCapture\file"

	$c = 0
	while (Test-Path "$screenCapturePathBase$c.bmp") {
		$c++
	}

	$File = "$screenCapturePathBase$c.bmp"

	while( $true ) {
		try{
			Add-Type -AssemblyName System.Windows.Forms
			[Windows.Forms.Sendkeys]::SendWait("{PrtSc}")  
			start-sleep -Milliseconds 250
			$bitmap = [Windows.Forms.Clipboard]::GetImage()  
			$bitmap.Save($File) 
			
			Write-Output "Screenshot saved to: $File"
			break;
		} catch{ 
			Write-Output "."
		}
	}

	[Windows.Forms.Clipboard]::Clear()
}

Get-Screen
