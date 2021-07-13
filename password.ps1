function fixLength($key) {
	$size = 8 - ($key.length % 8)
	
	for($i = 0; $i -lt $size; $i ++) {
		$key += $key[$i]
	}
	
	return $key
}

function getPin($msg) {
	$key = Read-Host $msg -AsSecureString
	$key = (New-Object System.Management.Automation.PSCredential("empty", $key)).GetNetworkCredential().Password;
	$key = fixLength($key)
	return ConvertTo-SecureString $key -AsPlainText -Force
}

function encode($plaintext, $key) {
	$cyphertext = ""
	$keyposition = 0
	$KeyArray = $key.ToCharArray()
	$plaintext.ToCharArray() | foreach-object -process {
		$cyphertext += [char]([byte][char]$_ -bxor $KeyArray[$keyposition])
		$keyposition += 1
		if ($keyposition -eq $key.Length) {$keyposition = 0}
	}
	return $cyphertext
}

function getPlaintext($creds) {
	$creds = New-Object System.Management.Automation.PSCredential ("anonym", $creds)
	return $creds.GetNetworkCredential().Password
}

function convert-secrets($file) {
	write-host "Processing $file credentials"
	$file = "$home\.secret\$file"

	if( ((Test-Path $file) -eq $false) ) {
		write-host "Ups"
		return
	}

	$key = getPlaintext (Read-Host -AsSecureString  "Enter current unlock key ")
	$temp = Import-CliXml -Path  $file
	$password = (encode $temp.GetNetworkCredential().Password $key) | ConvertTo-SecureString -AsPlainText -Force
	$key = getPin("Enter new unlock key")
	$newPass = ConvertFrom-SecureString $password -SecureKey $pin | ConvertTo-SecureString -AsPlainText -Force

	New-Object System.Management.Automation.PSCredential ($temp.UserName, $newPass) | Export-CliXml -Path $file
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
		$newPass = ConvertFrom-SecureString $password -SecureKey $key | ConvertTo-SecureString -AsPlainText -Force
		New-Object System.Management.Automation.PSCredential ($user, $newPass) | Export-CliXml -Path $file
	}
	
	$temp = Import-CliXml -Path  $file

	$secureString = ConvertTo-SecureString $temp.GetNetworkCredential().password -SecureKey $key

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
