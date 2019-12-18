########################################################################################################################
# Written by: Joshua Stenhouse joshuastenhouse@gmail.com
################################################
# Description:
# This script creates a report on the active SQL DB live mounts within the Rubrik clusters specified, requires admin user with same login/password on each Rubrik cluster specified
################################################ 
# Requirements:
# - Run PowerShell as administrator with command "Set-ExecutionPolcity unrestricted" on the host running the script
# - A Rubrik cluster or EDGE appliance, network access to it and credentials to login
# - At least 1 SQL Live mount to report on
# - PowerShell 5.1 and Rubrik CDM 5.0+
# - Admin rights to Rubrik, same credentials on each cluster specified
# - Report on multiple clusters by adding more. I.E $RubrikClusters = "rubrik1.lab.local","rubrik2.lab.local"
################################################
# Legal Disclaimer:
# This script is written by Joshua Stenhouse and is not supported under any support program or service. 
# All scripts are provided AS IS without warranty of any kind. 
# The author further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. 
# The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. 
# In no event shall its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if the author has been advised of the possibility of such damages.
################################################
# Configure the variables below
################################################
$RubrikClusters = "emea1-rbk01.rubrikdemo.com"
# Directory to store credentials
$ScriptDirectory = "/Users/promise/rubrik/rubrik/powershell/RubrikSQLLiveMountReportv1"
# Directory to store report results
$CSVOutputDirectory = "/Users/promise/rubrik/rubrik/powershell/RubrikSQLLiveMountReportv1"
# Location of logo file for HTML report, included in zip file
$LogoFile = $ScriptDirectory + "/logo.png"
# Configure max live mounts per user
$MaxLiveMounts = 10
$MaxLiveMountDays = 7
# HTML Color codes used for report rows
$HTMLColorGood = "#000000"
$HTMLColorBad = "#e60000"
# Email settings
$EmailTo = "promise.owolabi@rubrik.com"
$EmailFrom = "rubrik@lab.local"
$EmailServer = "localhost"
# Email subject
$EmailSubject = "Rubrik SQL Live Mount Report"
################################################
# Nothing to configure below this line - Starting the main function of the script
################################################
##################################
# Importing Rubrik credentials
##################################
# Setting credential file
$RubrikCredentialsFile = $ScriptDirectory + "/RubrikCredentials.xml"
# Testing if file exists
$RubrikCredentialsFileTest =  Test-Path $RubrikCredentialsFile
# IF doesn't exist, prompting and saving credentials
IF ($RubrikCredentialsFileTest -eq $False)
{
$RubrikCredentials = Get-Credential -Message "Enter Rubrik login credentials"
$RubrikCredentials | EXPORT-CLIXML $RubrikCredentialsFile -Force
}
ELSE
{
# Importing credentials
$RubrikCredentials = IMPORT-CLIXML $RubrikCredentialsFile
}
# Setting credentials
$RubrikUser = $RubrikCredentials.UserName
$RubrikPassword = $RubrikCredentials.GetNetworkCredential().Password
##################################
# Creating the Get-TimeZoneOffsets function
##################################
Function Get-TimeZoneOffsets {
Param ($TimeZone)

# Example of function:
# $TimeZone = "America/New York"
# $TimeZoneOffsets = Get-TimeZoneOffsets -TimeZone $TimeZone

# Replacing space with underscore in timezone name
$TimeZone = $TimeZone.Replace(" ","_").TrimEnd()
# Creating URL
$WorldTimeURL = "http://worldtimeapi.org/api/timezone/" + $TimeZone
# GET to world time API
Try
{
$WorldTime = Invoke-RestMethod -Uri $WorldTimeURL -Method GET
$Status = "Success"
}
Catch
{
$Status = "Failed"
$ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
}
# Selecting UTC offset
$UTCOffset = $WorldTime.utc_offset
# Setting hours and minutes of offset from UTC
IF ($Status -eq "Success")
{
$HoursToAdd = $UTCOffset.SubString(0,3)
$MinutesToAdd = $UTCOffset.SubString(3).Replace(":","").TrimEnd()
}
# Setting both to 0 if $Status Failed
IF ($Status -eq "Failed")
{
$HoursToAdd = "UseLast"
$MinutesToAdd = "UseLast"
}
# Returning offsets
Return $HoursToAdd,$MinutesToAdd
}
##################################
# Creating the Convert-UNIXTime function
##################################
Function Convert-UNIXTime {
Param ($UNIXTime)

# Example: $PSTime = Convert-UNIXTime -UNIXTime $UNIXTime

# Step 1 - Removing characters and trimming snapshot string for conversion
$PSTimeStep1 = $UNIXTime.Replace("T"," ").Replace("Z"," ").TrimEnd()
# Step 2 - Removing last 4 characters
$PSTimeStep2 = $PSTimeStep1.Substring(0,$PSTimeStep1.Length-4)
# Step 3 - Converting string to PowerShell datetime object
$PSTimeStep3 = ([datetime]::ParseExact($PSTimeStep2,”yyyy-MM-dd HH:mm:ss”,$null))
# Returning Result
Return $PSTimeStep3
}
##################################
# Adding certificate exception and TLS 1.2 to prevent API errors
##################################
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
##################################
# Calculating timezone of machine running script
##################################
$SystemDateTime = Get-Date
sleep 1
$UTCDateTime = [System.DateTime]::UtcNow
# Caculating difference
$SystemTimeGapToUTC = NEW-TIMESPAN –Start $UTCDateTime –End $SystemDateTime
$SystemTimeGapToUTCInHours = $SystemTimeGapToUTC.TotalHours
$SystemTimeGapToUTCInHours = [Math]::Round($SystemTimeGapToUTCInHours, 1)
# Getting time for Ms conversion to find source timestamp of live mounted DB
$Start = Get-Date -Day 1 -Month 1 -Year 1970 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
################################################
# Creating Arrays to Store Results
################################################
$RubrikSQLDBUserTable = @()
$RubrikSQLDBLiveMounts = @()
################################################
# Getting SQL DB Live Mounts for each Rubrik cluster
################################################
ForEach ($RubrikCluster in $RubrikClusters)
{
# Output to host
"--------------------------------
Processing: $RubrikCluster"
##################################
# Building Rubrik API string & invoking REST API
##################################
$v1BaseURL = "https://" + $RubrikCluster + "/api/v1/"
$v2BaseURL = "https://" + $RubrikCluster + "/api/v2/"
$InternalURL = "https://" + $RubrikCluster + "/api/internal/"
$LiveMountMgmtURL = "https://" + $RubrikCluster + "/web/bin/index.html#/live_mounts/mssql"
$RubrikSessionURL = $v1BaseURL + "session"
$Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($RubrikUser+":"+$RubrikPassword))}
$Type = "application/json"
# Authenticating with API
Try 
{
$RubrikSessionResponse = Invoke-RestMethod -Uri $RubrikSessionURL -Headers $Header -Method POST -ContentType $Type
}
Catch 
{
$_.Exception.ToString()
$error[0] | Format-List -Force
}
# Extracting the token from the JSON response
$RubrikSessionHeader = @{'Authorization' = "Bearer $($RubrikSessionResponse.token)"}
##########################
# Getting Cluster Info
##########################
$ClusterInfoURL = $v1BaseURL+"cluster/me"
Try 
{
$ClusterInfo = Invoke-RestMethod -Uri $ClusterInfoURL -TimeoutSec 100 -Headers $RubrikSessionHeader -ContentType $Type
}
Catch
{
$ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
}
# Setting variables
$ClusterID = $ClusterInfo.id
$ClusterVersion = $ClusterInfo.version
$ClusterName = $ClusterInfo.name
$ClusterTimezone = $ClusterInfo.timezone.timezone
$ClusterLocation = $ClusterInfo.geolocation.address
##########################
# Getting Cluster Timezone offsets from custom function
##########################
$ClusterTimeZoneOffsets = Get-TimeZoneOffsets -TimeZone $ClusterTimezone
$ClusterHoursToAdd = $ClusterTimeZoneOffsets | Select -First 1
$ClusterMinutesToAdd = $ClusterTimeZoneOffsets | Select -Last 1
##################################
# Getting list of Users
##################################
$RubrikUsersURL = $InternalURL+"user"
Try 
{
$RubrikUsers = Invoke-RestMethod -Uri $RubrikUsersURL -TimeoutSec 100 -Headers $RubrikSessionHeader -ContentType $Type
}
Catch 
{
$ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
}
##################################
# Getting list of SLA Domains
##################################
$SLAListURL = $v2BaseURL+"sla_domain"
Try 
{
$SLAListJSON = Invoke-RestMethod -Uri $SLAListURL -TimeoutSec 100 -Headers $RubrikSessionHeader -ContentType $Type
$SLAList = $SLAListJSON.data
}
Catch 
{
$ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
}
##################################
# Getting list of MS SQL DBs
##################################
$SQLDBListURL = $v1BaseURL+"mssql/db?limit=5000"
Try 
{
$SQLDBListJSON = Invoke-RestMethod -Uri $SQLDBListURL -TimeoutSec 100 -Headers $RubrikSessionHeader -ContentType $Type
$SQLDBList = $SQLDBListJSON.data
}
Catch 
{
$ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
}
##################################
# Getting list of MS SQL Live Mounts
##################################
$SQLDBLiveMountsURL = $v1BaseURL+"mssql/db/mount?limit=2000"
Try 
{
$SQLDBLiveMountsJSON = Invoke-RestMethod -Uri $SQLDBLiveMountsURL -TimeoutSec 100 -Headers $RubrikSessionHeader -ContentType $Type
$SQLDBLiveMounts = $SQLDBLiveMountsJSON.data
}
Catch 
{
$ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
}
# Counting
$SQLDBLiveMountCount = $SQLDBLiveMounts.Count
# Output to host
"SQLLiveMounts: $SQLDBLiveMountCount"
##################################
# Getting Totals Per User
##################################
# Getting list of users
$SQLDBLiveMountUsers = $SQLDBLiveMounts | Sort-Object OwnerName -Unique
# For each user counting mounts and adding to table
ForEach ($SQLDBLiveMountUser in $SQLDBLiveMountUsers)
{
# Setting variables
$SQLDBOwner = $SQLDBLiveMountUser.OwnerName
$SQLDBOwnerID = $SQLDBLiveMountUser.OwnerId
$SQLDBOwnerIDLong = "User:::" + $SQLDBOwnerID
# Counting DBs mounted
$SQLDBLiveMountCount = $SQLDBLiveMounts | Where-Object {$_.ownerId -eq $SQLDBOwnerID} | Measure | Select -ExpandProperty Count
# Deciding if above quota
IF ($SQLDBLiveMountCount -gt $MaxLiveMounts)
{$SQLDBUserQuotaExceeded = $TRUE}
ELSE
{$SQLDBUserQuotaExceeded = $FALSE}
# Getting user info
$SQLDBUserInfo = $RubrikUsers | Where-Object {$_.id -eq $SQLDBOwnerIDLong}
$SQLDBOwnerFirstName = $SQLDBUserInfo.firstName
$SQLDBOwnerLastName = $SQLDBUserInfo.lastName
$SQLDBOwnerEmailAddress = $SQLDBUserInfo.emailAddress
# Adding result
$RubrikSQLDBUser = New-Object PSObject
$RubrikSQLDBUser | Add-Member -MemberType NoteProperty -Name "RubrikCluster" -Value $ClusterName
$RubrikSQLDBUser | Add-Member -MemberType NoteProperty -Name "OwnerID" -Value $SQLDBOwnerID
$RubrikSQLDBUser | Add-Member -MemberType NoteProperty -Name "Owner" -Value $SQLDBOwner
$RubrikSQLDBUser | Add-Member -MemberType NoteProperty -Name "FirstName" -Value $SQLDBOwnerFirstName
$RubrikSQLDBUser | Add-Member -MemberType NoteProperty -Name "LastName" -Value $SQLDBOwnerLastName
$RubrikSQLDBUser | Add-Member -MemberType NoteProperty -Name "EmailAddress" -Value $SQLDBOwnerEmailAddress
$RubrikSQLDBUser | Add-Member -MemberType NoteProperty -Name "Mounts" -Value $SQLDBLiveMountCount
$RubrikSQLDBUser | Add-Member -MemberType NoteProperty -Name "Quota" -Value $MaxLiveMounts
$RubrikSQLDBUser | Add-Member -MemberType NoteProperty -Name "Exceeded" -Value $SQLDBUserQuotaExceeded
$RubrikSQLDBUserTable += $RubrikSQLDBUser
}
##################################
# Getting Live Mount Ages
##################################
# For Each Live Mount
ForEach ($SQLDBLiveMount in $SQLDBLiveMounts)
{
# Setting variables
$SQLDBLiveMountID = $SQLDBLiveMount.id
$SQLDBLiveMountSourceDBID = $SQLDBLiveMount.sourceDatabaseId
$SQLDBLiveMountSourceDBName = $SQLDBLiveMount.sourceDatabaseName
$SQLDBLiveMountTargetInstanceID = $SQLDBLiveMount.targetInstanceId
$SQLDBLiveMountTargetHostName = $SQLDBLiveMount.targetRootName
$SQLDBLiveMountMountedDBID = $SQLDBLiveMount.mountedDatabaseId
$SQLDBLiveMountMountedDBName = $SQLDBLiveMount.mountedDatabaseName
$SQLDBLiveMountStatus = $SQLDBLiveMount.status
$SQLDBLiveMountOwnerID = $SQLDBLiveMount.ownerId
$SQLDBLiveMountOwnerName = $SQLDBLiveMount.ownerName
$SQLDBLiveMountRecoveryPointMS = $SQLDBLiveMount.sourceRecoveryPoint | Select -ExpandProperty timestampMs
$SQLDBLiveMountCreationDateUNIX = $SQLDBLiveMount.creationDate
# Counting total mounts of this source DB
$SQLDBLiveMountTotalCopies = $SQLDBLiveMounts | Where-Object {$_.sourceDatabaseId -eq $SQLDBLiveMountSourceDBID} | Measure | Select -ExpandProperty Count
# Selecting Owner info
$SQLDBLiveMountOwnerInfo = $RubrikSQLDBUserTable | Where-Object {$_.OwnerID -eq $SQLDBLiveMountOwnerID}
$SQLDBLiveMountOwnerEmail = $SQLDBLiveMountOwnerInfo.EmailAddress
$SQLDBLiveMountOwnerLiveMounts = $SQLDBLiveMountOwnerInfo.Mounts
$SQLDBLiveMountOwnerQuota = $SQLDBLiveMountOwnerInfo.Quota
$SQLDBLiveMountOwnerQuotaExceeded = $SQLDBLiveMountOwnerInfo.Exceeded
# Converting recoverypoint
$SQLDBLiveMountRecoveryPoint1 = $Start.AddMilliseconds($SQLDBLiveMountRecoveryPointMS)
# Adjusting timezone
$SQLDBLiveMountRecoveryPoint = $SQLDBLiveMountRecoveryPoint1.AddHours($ClusterHoursToAdd).AddMinutes($ClusterMinutesToAdd)
# Converting creation date
$SQLDBLiveMountCreationDate = Convert-UNIXTime -UNIXTime $SQLDBLiveMountCreationDateUNIX
# Getting age of live mount
$SQLDBLiveMountAgeHours = New-TimeSpan -Start $SQLDBLiveMountCreationDate -End $UTCDateTime | Select -ExpandProperty TotalHours
$SQLDBLiveMountAgeDays = New-TimeSpan -Start $SQLDBLiveMountCreationDate -End $UTCDateTime | Select -ExpandProperty TotalDays
# Adjusting timezone
$SQLDBLiveMountCreationDate = $SQLDBLiveMountCreationDate.AddHours($ClusterHoursToAdd).AddMinutes($ClusterMinutesToAdd)
# Rounding
$SQLDBLiveMountAgeHours = [Math]::Round($SQLDBLiveMountAgeHours, 2)
$SQLDBLiveMountAgeDaysRounded = [Math]::Round($SQLDBLiveMountAgeDays, 0)
$SQLDBLiveMountAgeDays = [Math]::Round($SQLDBLiveMountAgeDays, 2)
# Deciding if live mount above max days
IF ($SQLDBLiveMountAgeDaysRounded -gt $MaxLiveMountDays)
{$SQLDBLiveMountExceeded = $TRUE}
ELSE
{$SQLDBLiveMountExceeded = $FALSE}
##################################
# Getting Live Mount Storage Usage
##################################
$SQLDBLiveMountStorageURL = $InternalURL+"stats/per_mount_storage/" + $SQLDBLiveMountID
Try 
{
$SQLDBLiveMountStorageJSON = Invoke-RestMethod -Uri $SQLDBLiveMountStorageURL -TimeoutSec 100 -Headers $RubrikSessionHeader -ContentType $Type
$SQLDBLiveMountStorageBytes = $SQLDBLiveMountStorageJSON.value
}
Catch 
{
$ErrorMessage = $_.ErrorDetails; "ERROR: $ErrorMessage"
}
# Converting & rounding
$SQLDBLiveMountStorageMB = $SQLDBLiveMountStorageBytes / 1000 / 1000
$SQLDBLiveMountStorageMB = [Math]::Round($SQLDBLiveMountStorageMB,2)
$SQLDBLiveMountStorageGB = $SQLDBLiveMountStorageBytes / 1000 / 1000 / 1000
$SQLDBLiveMountStorageGB = [Math]::Round($SQLDBLiveMountStorageGB,2)
# Adding result
$RubrikSQLDBLiveMount = New-Object PSObject
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "RubrikCluster" -Value $ClusterName
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "ID" -Value $SQLDBLiveMountID
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "SourceDBID" -Value $SQLDBLiveMountSourceDBID
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "SourceDBName" -Value $SQLDBLiveMountSourceDBName
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "TotalCopies" -Value $SQLDBLiveMountTotalCopies
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "TargetInstanceID" -Value $SQLDBLiveMountTargetInstanceID
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "TargetHostName" -Value $SQLDBLiveMountTargetHostName
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "MountedDBID" -Value $SQLDBLiveMountMountedDBID
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "MountedDBName" -Value $SQLDBLiveMountMountedDBName
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "StorageUsedBytes" -Value $SQLDBLiveMountStorageBytes
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "StorageUsedMB" -Value $SQLDBLiveMountStorageMB
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "StorageUsedGB" -Value $SQLDBLiveMountStorageGB
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "OwnerID" -Value $SQLDBLiveMountOwnerID
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "OwnerName" -Value $SQLDBLiveMountOwnerName
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "OwnerEmail" -Value $SQLDBLiveMountOwnerEmail
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "OwnerLiveMounts" -Value $SQLDBLiveMountOwnerLiveMounts
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "OwnerQuota" -Value $SQLDBLiveMountOwnerQuota
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "OwnerQuotaExceeded" -Value $SQLDBLiveMountOwnerQuotaExceeded
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "Status" -Value $SQLDBLiveMountStatus
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "DBTimeStamp" -Value $SQLDBLiveMountRecoveryPoint
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "Created" -Value $SQLDBLiveMountCreationDate
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "AgeHours" -Value $SQLDBLiveMountAgeHours
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "AgeDays" -Value $SQLDBLiveMountAgeDays
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "AgeMax" -Value $MaxLiveMountDays
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "AgeExceeded" -Value $SQLDBLiveMountExceeded
$RubrikSQLDBLiveMount | Add-Member -MemberType NoteProperty -Name "URL" -Value $LiveMountMgmtURL
$RubrikSQLDBLiveMounts += $RubrikSQLDBLiveMount
}
##################################
# End of for each Rubrik cluster below
##################################
}
# End of for each Rubrik cluster above
##################################
# Getting Totals
##################################
$TotalLiveMounts = $SQLDBLiveMounts | Measure | Select -ExpandProperty Count
$TotalUsers = $RubrikSQLDBUserTable | Measure | Select -ExpandProperty Count
$TotalUsersAboveQuota = $RubrikSQLDBUserTable | Where-Object {$_.Exceeded -eq $TRUE} | Measure | Select -ExpandProperty Count
$TotalLiveMountsAboveMaxAge = $RubrikSQLDBLiveMounts | Where-Object {$_.AgeExceeded -eq $TRUE} | Measure | Select -ExpandProperty Count
$AverageMountAgeDays = $RubrikSQLDBLiveMounts | Select -ExpandProperty AgeDays | Measure -Average | Select -ExpandProperty Average
$MaxMountAgeDays = $RubrikSQLDBLiveMounts | Select -ExpandProperty AgeDays | Measure -Maximum | Select -ExpandProperty Maximum
$TotalSourceDBs = $RubrikSQLDBLiveMounts | Select -ExpandProperty SourceDBID -Unique | Measure | Select -ExpandProperty Count
# Rounding
$AverageMountAgeDays = [Math]::Round($AverageMountAgeDays,2)
# Storage totals
$TotalStorageUsedBytes = $RubrikSQLDBLiveMounts | Select -ExpandProperty StorageUsedBytes | Measure -Sum | Select -ExpandProperty Sum
$AverageStorageUsedBytes = $RubrikSQLDBLiveMounts | Select -ExpandProperty StorageUsedBytes | Measure -Average | Select -ExpandProperty Average
$MaxStorageUsedBytes = $RubrikSQLDBLiveMounts | Select -ExpandProperty StorageUsedBytes | Measure -Maximum | Select -ExpandProperty Maximum
# Converting and rounding
$TotalStorageUsedMB = $TotalStorageUsedBytes / 1000 / 1000
$TotalStorageUsedMB = [Math]::Round($TotalStorageUsedMB,2)
$TotalStorageUsedGB = $TotalStorageUsedBytes / 1000 / 1000 / 1000
$TotalStorageUsedGB = [Math]::Round($TotalStorageUsedGB,2)
$AverageStorageUsedMB = $AverageStorageUsedBytes / 1000 / 1000
$AverageStorageUsedMB = [Math]::Round($AverageStorageUsedMB,2)
$MaxStorageUsedMB = $MaxStorageUsedBytes / 1000 / 1000 
$MaxStorageUsedMB = [Math]::Round($MaxStorageUsedMB,2)
# If any above 1 rounding to nearest
IF ($TotalStorageUsedMB -gt 1){$TotalStorageUsedMB = [Math]::Round($TotalStorageUsedMB,0)}
IF ($AverageStorageUsedMB -gt 1){$AverageStorageUsedMB = [Math]::Round($AverageStorageUsedMB,0)}
IF ($MaxStorageUsedMB -gt 1){$MaxStorageUsedMB = [Math]::Round($MaxStorageUsedMB,0)}
# Output to host
"--------------------------------
TotalLiveMounts: $TotalLiveMounts
AboveMaxAge: $TotalLiveMountsAboveMaxAge
TotalUsers: $TotalUsers
AboveQuota: $TotalUsersAboveQuota"
####################################################################
# SMTP Body - HTML Email style settings
####################################################################
# Start of HTML structure
$HTMLStart = @"
<!DOCTYPE html>
<html>
<head>
<style>

a {
    color: black;
}

a:link {
    text-decoration: none;
}

table.table1 {
  border-collapse: collapse;
  width: 100%;
}
table.table1 th {
  text-align: center;
  padding: 8px;
  border-bottom: 1px solid #ddd;
  background-color: white;
  color: #696969;
  font-size:16px
}
table.table1 td {
  text-align: center;
  padding: 8px;
  border-bottom: 1px solid #ddd;
  font-size:12px
}

table.table2 {
  border-collapse: collapse;
  width: 100%;
}
table.table2 th {
  text-align: center;
  padding: 8px;
  border-bottom: 1px solid #ddd;
  background-color: white;
  color: #00B2A9;
  font-size:14px
}
table.table2 td {
  text-align: center;
  padding: 8px;
  border-bottom: 1px solid #ddd;
  font-size:12px
}

</style>
</head>
<body>

<div style="overflow-x:auto;">

<table style="text-align: right; width: 100%;" border="0"; cellpadding="2"; cellspacing="2">
<tbody>
<tr>
<td style="vertical-align: top;"><img style="width: 350px; height: 95px;" alt="Rubrik" src="logo.png"><br>
</td>
</tr>
</tbody>
</table>

<br></br>
"@
# End of HTML structure
$HTMLEnd = @"
</div>

</body>
</html>
"@
##################################
# Creating HTML Summary table
##################################
$HTMLSummaryTable = @"
<table class="table1">
  <tr>
    <th>$SystemDateTime</th>
  </tr>
  <tr>
    <th>SQL Live Mount Summary</th>
  </tr>
</table>

<table class="table2">
  <tr>
    <th>Mounts</th>
    <td>$TotalLiveMounts</td>

    <th>TotalUsedGB</th>
    <td>$TotalStorageUsedGB</td>

    <th>Users</th>
    <td>$TotalUsers</td>

    <th>AverageAgeDays</th>
    <td>$AverageMountAgeDays</td>
  </tr>
 <tr>
    <th>MaxAgeDays</th>
    <td>$MaxLiveMountDays</td>

    <th>AverageUsedMB</th>
    <td>$AverageStorageUsedMB</td>

    <th>MountQuota</th>
    <td>$MaxLiveMounts</td>

    <th>OldestAgeDays</th>
    <td>$MaxMountAgeDays</td>
 </tr>
  <tr>
    <th>AboveMaxAge</th>
    <td>$TotalLiveMountsAboveMaxAge</td>

    <th>MaxUsedMB</th>
    <td>$MaxStorageUsedMB</td>

    <th>AboveQuota</th>
    <td>$TotalUsersAboveQuota</td>

    <th>TotalSourceDBs</th>
    <td>$TotalSourceDBs</td>
 </tr>
 </table>
 <br>
"@
##################################
# Creating Table 1 HTML structure
##################################
$HTMLTable1Start = @"
<table class="table1">
  <tr>
    <th>SQL Live Mounts By Oldest First</th>
  </tr>
</table>

<table class="table2">
  <tr>
    <th>Mounted<br>DB</th>
    <th>Mounted<br>Host</th>
    <th>Rubrik<br>Cluster</th>
    <th>Used<br>Storage</th>
    <th>Owner<br>(Mounts)</th>
    <th>Created</th>
    <th>Age</th>
    <th>Source<br>DB</th>
    <th>Timestamp</th>
  </tr>
"@
$HTMLTable1End = @"
</table>
<br>
"@
##################################
# Creating Table 1 HTML Rows
##################################
# Building email list by task to put the most important objects for viewing at the top
$Table1Data = $RubrikSQLDBLiveMounts | Sort-Object {[decimal]$_.AgeHours} -Descending
# Nulling out table, protects against issues with multiple runs in PowerShell ISE
$HTMLReportTable1Middle = $null
# Creating table row for each line
ForEach ($Row in $Table1Data) 
{
# Setting values
$HTML1RubrikCluster = $Row.RubrikCluster
$HTML1RubrikClusterURL = $Row.URL
$HTML1SourceDB = $Row.SourceDBName
$HTML1StorageUsedMB = $Row.StorageUsedMB
$HTML1StorageUsedGB = $Row.StorageUsedGB
$HTML1Timestamp = $Row.DBTimestamp
$HTML1MountedDB = $Row.MountedDBName
$HTML1MountedHost = $Row.TargetHostName
$HTML1Created = $Row.Created
$HTML1AgeDays = $Row.AgeDays
$HTML1AgeHours = $Row.AgeHours
$HTML1AgeExceeded = $Row.AgeExceeded
$HTML1Owner = $Row.OwnerName
$HTML1Email = $Row.OwnerEmail
$HTML1Mounts = $Row.OwnerLiveMounts
$HTML1OwnerQuota = $Row.OwnerQuota
$HTML1OwnerQuotaExceeded = $Row.OwnerQuotaExceeded
# Setting live mount colors
IF ($HTML1AgeExceeded -eq $TRUE){$HTMLAgeStatusColor =  $HTMLColorBad}
IF ($HTML1AgeExceeded -eq $FALSE){$HTMLAgeStatusColor =  $HTMLColorGood}
# Setting owner colors
IF ($HTML1OwnerQuotaExceeded -eq $TRUE){$HTMLOwnerStatusColor =  $HTMLColorBad}
IF ($HTML1OwnerQuotaExceeded -eq $FALSE){$HTMLOwnerStatusColor =  $HTMLColorGood}
# Deciding whether to show hours or days for age
IF ($HTML1AgeHours -lt 24)
{
$HTML1Age = [string]$HTML1AgeHours + " Hours"
}
ELSE
{
$HTML1Age = [string]$HTML1AgeDays + " Days"
}
# Deciding whether to show MB or GB
IF ($HTML1StorageUsedMB -gt 1000)
{
$HTML1StorageUsed = [string]$HTML1StorageUsedGB + " GB"
}
ELSE
{
$HTML1StorageUsed = [string]$HTML1StorageUsedMB + " MB"
}
# Building HTML table row
$HTMLReportTable1Row = "
<tr>
    <td>$HTML1MountedDB</td>
    <td>$HTML1MountedHost</td>
    <td><a href=$HTML1RubrikClusterURL>$HTML1RubrikCluster</a></td>
    <td>$HTML1StorageUsed</td>
    <td>$HTML1Email <font color=$HTML1OwnerQuotaExceeded>($HTML1Mounts)</font></td>
    <td>$HTML1Created</td>
    <td><font color=$HTMLAgeStatusColor>$HTML1Age</font></td>
    <td>$HTML1SourceDB</td>
    <td>$HTML1Timestamp</td> 
  </tr>
"
# Adding row to table
$HTMLReportTable1Middle += $HTMLReportTable1Row
}
##################################
# Putting Table 1 together
##################################
$HTMLTable1 = $HTMLTable1Start + $HTMLReportTable1Middle + $HTMLTable1End
##################################
# Creating Report
##################################
# Building HTML report:
$HTMLReport = $HTMLStart + $HTMLSummaryTable + $HTMLTable1 + $HTMLEnd
# Replacing any 100.00% strings with 100% for easier reading
$HTMLReport = $HTMLReport.Replace("100.00%","100%").TrimEnd()
##################################
# Creating CSVs
##################################
# Creating the file names
$RubrikSQLDBLiveMountFile = $CSVOutputDirectory + "/SQLLiveMounts-" + $SystemDateTime.ToString("yyyy-MM-dd") + "@" + $SystemDateTime.ToString("HH-mm-ss") + ".csv"
# Exporting to CSV
$RubrikSQLDBLiveMounts | Export-Csv -Path $RubrikSQLDBLiveMountFile -NoTypeInformation -Force
# Putting all 3 files together for the email attachement
$Attachments = "$RubrikSQLDBLiveMountFile","$LogoFile"
##################################
# Sending email using function
##################################
# Output to host
"--------------------------------
SendingEmailTo: $EmailTo"
# Sending email, configure the below to add additional settings like ssl etc
Try
{
Send-MailMessage -To $EmailTo -From $EmailFrom -Body $HTMLReport -Subject $EmailSubject -Attachments $Attachments -SmtpServer $EmailServer -BodyAsHtml 
}
Catch
{
$Error[0] | Format-List -Force
}
###############################################
# End of script
###############################################