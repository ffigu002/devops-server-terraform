param (
    [string]$username,
    [string]$targetsrv,
    [string]$keyVaultName,
    [string]$managedIdentity
)


Write-Host "target server is" ${targetsrv}

# $username=[string]${username}
# $targetsrv=[string]${targetsrv}

# $keyVaultName=[string]${keyVaultName}
# $managedIdentity=[string]${managedIdentity}

#TODO MI needs access to key vault

#Query Azure Key Vault for SQL Admin password
$response = Invoke-WebRequest -Uri 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.usgovcloudapi.net' -UseBasicParsing -Method GET -Headers @{Metadata="true"}
$content = $response.Content | ConvertFrom-Json
$KeyVaultToken = $content.access_token
$akv_Content = (Invoke-WebRequest -Uri "https://${keyVaultName}.vault.usgovcloudapi.net/secrets/AzDevOpsSqlPass?api-version=2016-10-01" -UseBasicParsing -Method GET -Headers @{Authorization="Bearer $KeyVaultToken"}).content
$value = ($akv_Content | ConvertFrom-JSON).value
$Password = $value


$targetsrvfull = "${targetsrv}" + ".database.usgovcloudapi.net"

Write-Host "full target server is" $targetsrvfull

#Create query strings to update databases
$masterUpdate = "CREATE USER " + "${managedIdentity}" + " FROM EXTERNAL PROVIDER;ALTER ROLE [dbmanager] ADD MEMBER " + "${managedIdentity}" +";"
$dbUpdate = "CREATE USER " + "${managedIdentity}" + " FROM EXTERNAL PROVIDER;ALTER ROLE [db_owner] ADD MEMBER " + "${managedIdentity}" + ";ALTER USER " + "${managedIdentity}" + " WITH DEFAULT_SCHEMA=dbo;"


#TODO Azure SQL identity requires Directory Reader Role
# Write-Host "full master update query is " $masterUpdate
# Write-Host "full db update query is " $dbUpdate

#Update Master database
sqlcmd -S $targetsrvfull -d master -Q $masterUpdate --authentication-method=ActiveDirectoryServicePrincipal -U ${username} -P $Password -l 30

#Update default configuration database
sqlcmd -S $targetsrvfull -d AzureDevOps_Configuration -Q $dbUpdate --authentication-method=ActiveDirectoryServicePrincipal -U ${username}  -P $Password -l 30

#Update default collection database
sqlcmd -S $targetsrvfull -d AzureDevOps_DefaultCollection -Q $dbUpdate --authentication-method=ActiveDirectoryServicePrincipal -U ${username}  -P $Password -l 30

Write-Host "Done"