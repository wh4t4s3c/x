[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)]
	[string[]]
	$DomainName
)

. $home\zengrc-connection\password.ps1

$creds = getCredentials "whois"
 
$responses = @()
$DomainName | ForEach-Object {
	$requestUri = "https://www.whoisxmlapi.com/whoisserver/WhoisService?apiKey=$($creds.GetNetworkCredential().password)&domainName=$_&outputFormat=JSON"
	$responses += Invoke-RestMethod -Method Get -Uri $requestUri
}
 
function Get-ValidDate ($Value, $Date) {
	$defaultDate = $Value."$($Date)Date"
 
	if (![string]::IsNullOrEmpty($defaultDate)) {
		return Get-Date $defaultDate
	}

	$normalizedDate = $Value.registryData."$($Date)DateNormalized"
 
	return [datetime]::ParseExact($normalizedDate, "yyyy-MM-dd HH:mm:ss UTC", $null)   
}
 
function Till-Expire ($Value) {
	$defaultDate = $Value."expiresDate"
 
	if (![string]::IsNullOrEmpty($defaultDate)) {
		return ((Get-Date $defaultDate) - (Get-Date)).days
	}

	$normalizedDate = $Value.registryData.expiresDateNormalized
 
	return ([datetime]::ParseExact($normalizedDate, "yyyy-MM-dd HH:mm:ss UTC", $null) - (Get-Date)).days
}
 
$properties = "domainName", 
	"domainNameExt", 
	@{N = "createdDate"; E = { Get-ValidDate $_ "created" } }, 
	@{N = "expiresDate"; E = { Get-ValidDate $_ "expires" } },
	@{N = "days left"; E = { Till-Expire $_ } },
	@{N = "contact"; e = { $_.registrant.organization } }
	#@{N = "updatedDate"; E = { Get-ValidDate $_ "updated" } },
	#"registrarName",
	#"contactEmail",
	#"estimatedDomainAge",
	#@{N = "registrant"; e = { $_.registrant.rawtext } },
 
$whoIsInfo = $responses.WhoisRecord | Select-Object -Property $properties | sort-object {[int]($_.left -replace '(\d+).*', '$1')}
 
$whoIsInfo | Export-Csv -NoTypeInformation domain-whois.csv
 
$whoIsInfo | Format-Table
