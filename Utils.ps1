## ZIP / UNZIP

function Zip-String {
[CmdletBinding()]
    Param (
		[Parameter(ValueFromPipeline)][String] $inputString
    )
	Process {
		$input = $inputString.ToCharArray();
		$ms = New-Object IO.MemoryStream;
		$cs = New-Object System.IO.Compression.GZipStream ($ms, [Io.Compression.CompressionMode]"Compress");
		$cs.Write($input, 0, $input.Length);
		$cs.Close();
		[Convert]::ToBase64String($ms.ToArray());
		$ms.Close()
	}
}

function Unzip-String {
[CmdletBinding()]
    param(
		[Parameter(ValueFromPipeline)][String] $compString
    )   
    process {
		$comp = [System.Convert]::FromBase64String($compString)
        
        $ms = New-Object System.IO.MemoryStream
        $ms.Write($comp, 0, $comp.Length)
        $ms.Seek(0,0) | Out-Null
        $cs = New-Object System.IO.Compression.GZipStream($ms, [IO.Compression.CompressionMode]"Decompress")

		$output = New-Object System.IO.StreamReader($cs)
		$output.ReadToEnd()
    }
}

Set-Alias zs Zip-String
Set-Alias us Unzip-String

## Base64

function Base64-to-String {
[CmdletBinding()]
    param(
		[Parameter(ValueFromPipeline)][String] $base64
    )   
    process {
		$base = [System.Convert]::fromBase64String($base64)
		[System.Text.Encoding]::UTF8.GetString($base)
	}
}

function String-to-Base64 {
[CmdletBinding()]
    param(
		[Parameter(ValueFromPipeline)][String] $plaintext
    )   
    process {
		$base = [System.Text.Encoding]::UTF8.GetBytes($plaintext)
		[System.Convert]::toBase64String($base)
	}
}

Set-Alias b2s Base64-to-String
Set-Alias s2b String-to-Base64

## base64 unicode

function Base64-to-String-Unicode {
[CmdletBinding()]
    param(
		[Parameter(ValueFromPipeline)][String] $base64
    )   
    process {
		$base = [System.Convert]::fromBase64String($base64)
		[System.Text.Encoding]::Unicode.GetString($base)
	}
}

function String-to-Base64-Unicode {
[CmdletBinding()]
    param(
		[Parameter(ValueFromPipeline)][String] $plaintext
    )   
    process {
		$base = [System.Text.Encoding]::Unicode.GetBytes($plaintext)
		[System.Convert]::toBase64String($base)
	}
}

Set-Alias b2su Base64-to-String-Unicode
Set-Alias s2bu String-to-Base64-Unicode

## command to hex striong

function Command-to-Hex {
[CmdletBinding()]
    param(
		[Parameter(ValueFromPipeline)][String] $command
    )   
    process {
		$output = (iex "$command"|out-string|format-hex)
		$c=""
		ForEach($byte in $output.bytes){
			$c += "{0:x2}" -f $byte
		}
		$c.tostring()
	}
}

function String-to-Hex {
[CmdletBinding()]
    param(
		[Parameter(ValueFromPipeline)][String] $output
    )   
    process {
		$c="";
		ForEach($byte in ($output|format-hex).bytes){
			$c += "{0:x2}" -f $byte
		}
		$c.tostring()
	}
}

function Hex-to-String {
[CmdletBinding()]
    param(
		[Parameter(ValueFromPipeline)][String] $hexString
    )   
    process {
		$d = [byte[]]::new($hexString.Length / 2);
		For($i = 0; $i -lt $hexString.Length; $i += 2){
			$d[$i/2] = [convert]::ToByte($hexString.Substring($i, 2), 16)
		}
		[System.Text.Encoding]::UTF8.GetString($d)
	}
}

Set-Alias c2h Command-to-Hex
Set-Alias s2h String-to-Hex
Set-Alias h2s Hex-to-String

## secrets

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

function Get-Secret($file) {
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

Set-Alias gs Get-Secret
