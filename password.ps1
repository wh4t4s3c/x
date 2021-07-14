function getPin($msg) {
	$password = Read-Host $msg -AsSecureString
	# need plaint text to make sure the length is correct
	$password = (New-Object System.Management.Automation.PSCredential("empty", $password)).GetNetworkCredential().Password;

	$iterations = 5000
	$salt = @(139, 220, 45, 127, 147, 146, 120, 4, 198, 164, 170, 246, 212, 138, 134, 112, 74, 204, 210, 137, 231, 228, 121, 190, 169, 92, 116, 6, 165, 70, 251, 21)
	$saltBytes = [Text.Encoding]::Unicode.GetBytes($salt) 
	$deriveBytes = new-Object Security.Cryptography.Rfc2898DeriveBytes($password, $saltBytes, $iterations)
	return $deriveBytes.GetBytes(32) 
}

function rekey-secret($file) {
	write-host "Processing $file credentials"
	$file = "$home\.secret\$file"

	if( ((Test-Path $file) -eq $false) ) {
		write-host "Ups"
		return
	}

	$key = getPin("Enter current unlock key")
	$temp = Import-CliXml -Path  $file
	$password = ConvertTo-SecureString $temp.GetNetworkCredential().password -Key $key
	$pin = getPin("Enter new unlock key")
	$newPass = ConvertFrom-SecureString $password -Key $pin | ConvertTo-SecureString -AsPlainText -Force

	New-Object System.Management.Automation.PSCredential ($temp.UserName, $newPass) | Export-CliXml -Path $file
}

function rekey-allsecrets {
	$a=(get-item $home/.secret/*).name
	$key = getPin("Enter current unlock key")
	$pin = getPin("Enter new unlock key")

	$a | foreach {
		write-host "Processing $_ credentials"
		$file = "$home\.secret\$_"
		$temp = Import-CliXml -Path  $file
		$password = ConvertTo-SecureString $temp.GetNetworkCredential().password -Key $key
		$newPass = ConvertFrom-SecureString $password -Key $pin | ConvertTo-SecureString -AsPlainText -Force
		New-Object System.Management.Automation.PSCredential ($temp.UserName, $newPass) | Export-CliXml -Path $file
	}
}

function getCredentials($file) {
	write-host "Processing $file credentials"
	$file = "$home\.secret\$file"

	if( (Test-Path "$home\.secret") -eq $false ) {
		[void](New-Item "$home\.secret" -ItemType Directory)
	}

	$key = getPin("Enter unlock key")

	if( ((Test-Path $file) -eq $false) ) {
		$user = Read-Host "Enter Access Key ID "
		$password = Read-Host -AsSecureString  "Enter Secret Key "
		$newPass = ConvertFrom-SecureString $password -Key $key | ConvertTo-SecureString -AsPlainText -Force
		New-Object System.Management.Automation.PSCredential ($user, $newPass) | Export-CliXml -Path $file
	}
	
	$temp = Import-CliXml -Path  $file

	$secureString = ConvertTo-SecureString $temp.GetNetworkCredential().password -Key $key

	return New-Object System.Management.Automation.PSCredential ($temp.UserName, $secureString)
}

function getBasicHeader($file) {
	$credential = getCredentials  $file

	if($credential.username[0] -eq '.') {
		$auth = @{
			Authorization = "$($credential.UserName.Substring(1)) $($credential.GetNetworkCredential().Password)"
		}
	} else {
		$encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($credential.UserName):$($credential.GetNetworkCredential().Password)"));
		$auth = @{
			Authorization = "Basic $encoded"
		}
	}

	
	return $auth
}

function getBearerHeader($file) {
	$credential = getCredentials  $file

	$auth = @{
		Authorization = "Bearer $($credential.GetNetworkCredential().Password)"
	}
	
	return $auth
}

function getAPIHeader($file, $key, $value) {
	$credential = getCredentials  $file

	$value = $value -f $credential.UserName, $credential.GetNetworkCredential().Password

	$auth = @{
		$key = $value
	}
	
	return $auth
}

function getOAuthHeader($file, $url, $contentType, $body) {
	$token = [Environment]::GetEnvironmentVariable($file)
	if($token -eq $null) {
		$credential = getCredentials $file

		$body = $body -f $credential.UserName, $credential.GetNetworkCredential().Password

		$token = Invoke-RestMethod -Method Post -ContentType $contentType -B $body -Uri $url #-Proxy "http://127.0.0.1:8888"
		
		[Environment]::SetEnvironmentVariable($file, ($token|ConvertTo-Json))
	} else {
		$token = $token | ConvertFrom-Json
	}
	
	return $token
}

function getToken($file, $url) {
	$token = [Environment]::GetEnvironmentVariable($file)
	if($token -eq $null) {
		$credential = getBasicHeader $file

		$token = Invoke-RestMethod -headers $credential $url #-Proxy "http://127.0.0.1:8888"
		
		[Environment]::SetEnvironmentVariable($file, ($token|ConvertTo-Json))
	} else {
		$token = $token | ConvertFrom-Json
	}
	
	return $token
}

$logFile = ".\log.txt"
New-Item -Path $logFile -Force | Out-Null

# prints log msg to screen and log file
function log($msg) {
	Write-Host $msg
	Add-Content -Path $logFile -Value $msg
}
