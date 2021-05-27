$env:AWS_ACCESS_KEY_ID = $args[0]
$env:AWS_SECRET_ACCESS_KEY = $args[1]
sr us-east-1
$session_token_response = (aws sts get-session-token) | ConvertFrom-Json
$env:AWS_ACCESS_KEY_ID = $session_token_response.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $session_token_response.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $session_token_response.Credentials.SessionToken
$env:AWS_SESSION_EXPIRATION = $session_token_response.Credentials.Expiration

if($env:AWS_SESSION_TOKEN -ne $null) {
	$id = aws sts get-caller-identity | convertfrom-json
	write-host "`n`nAccount $($id.Account)"
	write-host "User    $($id.Arn)"
	
	Write-host "Permissions"
	aws opsworks describe-permissions --iam-user-arn $id.Arn
}

$session_token_response



