function Zip-String ($inputString){
	$input = $inputString.ToCharArray();
	$ms = New-Object IO.MemoryStream;
	$cs = New-Object System.IO.Compression.GZipStream ($ms, [Io.Compression.CompressionMode]"Compress");
	$cs.Write($input, 0, $input.Length);
	$cs.Close();
	[Convert]::ToBase64String($ms.ToArray());
	$ms.Close()
}

function Unzip-String {
    param(
		[Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
		[string]$compString
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

function Save-Secret() {
    param(
		[string]$secretFile
    )   
	if( (Test-Path "$home\.secret") -eq $false) {
		[void](new-Item "$home\.secret" -ItemType Directory)
	}
	Read-Host -AsSecureString  "Enter password " | convertfrom-securestring | out-file $home"\.secret\$secretFile"
}

function Restore-Secret() {
    param(
		[string]$secretFile
    )   
	$sp = Get-Content $home"\.secret\$secretFile" | ConvertTo-SecureString
	$up = (New-Object PSCredential "user",$sp).GetNetworkCredential().Password
	$up
}

Set-Alias ss Save-Secret
Set-Alias rs Restore-Secret

function B64-UTF-From() {
    param(
		[string]$base64
    )   
	[System.Text.Encoding]::UTF8.GetString([System.Convert]::fromBase64String($base64))
}

function B64-From() {
    param(
		[string]$base64
    )   
	[System.Text.Encoding]::Unicode.GetString([System.Convert]::fromBase64String($base64))
}

function B64-UTF-To() {
    param(
		[string]$plaintext
    )   
	[System.Convert]::toBase64String([System.Text.Encoding]::UTF8.GetBytes($plaintext))
}

function B64-To() {
    param(
		[string]$plaintext
    )   
	[System.Convert]::toBase64String([System.Text.Encoding]::Unicode.GetBytes($plaintext))
}

Set-Alias but B64-UTF-To
Set-Alias buf B64-UTF-From
Set-Alias bt B64-To
Set-Alias bf B64-From

function Hex-Command-To() {
    param(
		[string]$command
    )   
	$c="";ForEach($byte in (iex "$command"|out-string|format-hex).bytes){$c+="{0:x2}" -f $byte};$c=$c.tostring();
	$c
}

function Hex-Command-From() {
    param(
		[string]$input
    )   
 
	$d=[byte[]]::new($input.Length / 2);For($i=0;$i -lt $input.Length; $i+=2){$d[$i/2] = [convert]::ToByte($input.Substring($i, 2), 16)};[System.Text.Encoding]::UTF8.GetString($d)
}

Set-Alias hct Hex-Command-To
Set-Alias hcf Hex-Command-From

function Hex-To() {
    param(
		[string]$command
    )   
	$c="";ForEach($byte in ($command|format-hex).bytes){$c+="{0:x2}" -f $byte};$c=$c.tostring();$c
}

function Hex-Command-To() {
    param(
		[string]$command
    )   
	$c="";ForEach($byte in (iex "$command"|out-string|format-hex).bytes){$c+="{0:x2}" -f $byte};$c=$c.tostring();
	$c
}

function Hex-From() {
    param(
		[Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
		[string]$hexString
    )   
 
	$d=[byte[]]::new($hexString.Length / 2);
	
	For($i=0;$i -lt $hexString.Length; $i+=2){
		$d[$i/2] = [convert]::ToByte($hexString.Substring($i, 2), 16)
	};
	
	[System.Text.Encoding]::UTF8.GetString($d)
}

Set-Alias ht Hex-To
Set-Alias hct Hex-Command-To
Set-Alias hf Hex-From
