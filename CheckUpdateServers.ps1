function trigger-AvailableSupInstall
{
 Param
(
 [String][Parameter(Mandatory=$True, Position=1)] $Computername,
 [String][Parameter(Mandatory=$True, Position=2)] $SupName

)
Begin
{
 $AppEvalState0 = "0"
 $AppEvalState1 = "1"
 $ApplicationClass = [WmiClass]"root\ccm\clientSDK:CCM_SoftwareUpdatesManager"
}

Process
{
If ($SupName -Like "All" -or $SupName -like "all")
{
 Foreach ($Computer in $Computername)
{
 $Application = (Get-WmiObject -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate -ComputerName $Computer | Where-Object { $_.EvaluationState -like "*$($AppEvalState0)*" -or $_.EvaluationState -like "*$($AppEvalState1)*"})
 Invoke-WmiMethod -Class CCM_SoftwareUpdatesManager -Name InstallUpdates -ArgumentList (,$Application) -Namespace root\ccm\clientsdk -ComputerName $Computer

}

}
 Else

{
 Foreach ($Computer in $Computername)
{
 $Application = (Get-WmiObject -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate -ComputerName $Computer | Where-Object { $_.EvaluationState -like "*$($AppEvalState)*" -and $_.Name -like "*$($SupName)*"})
 Invoke-WmiMethod -Class CCM_SoftwareUpdatesManager -Name InstallUpdates -ArgumentList (,$Application) -Namespace root\ccm\clientsdk -ComputerName $Computer

}

}
}
End {}
}


#Server list 
$Servers = Get-Content ".\serverslist.txt"

#Define array
$Updates = @()
 
#Checking updates in Software Center
Try{
   $Updates = Invoke-Command -cn $Servers {
       $Application =  Get-WmiObject -Namespace "root\ccm\clientsdk" -Class CCM_SoftwareUpdate 
       If(!$Application){
               $Object = New-Object PSObject -Property ([ordered]@{      
                       ArticleId         = " - "
                       Publisher         = " - "
                       Software          = " - "
                       Description       = " - "
                       State             = " - "
                       StartTime         = " - "
                       DeadLine          = " - "
               })
 
               $Object
       }
       Else{
           Foreach ($App in $Application){
 
               $EvState = Switch ( $App.EvaluationState  ) {
                       '0'  { "None" } 
                       '1'  { "Available" } 
                       '2'  { "Submitted" } 
                       '3'  { "Detecting" } 
                       '4'  { "PreDownload" } 
                       '5'  { "Downloading" } 
                       '6'  { "WaitInstall" } 
                       '7'  { "Installing" } 
                       '8'  { "PendingSoftReboot" } 
                       '9'  { "PendingHardReboot" } 
                       '10' { "WaitReboot" } 
                       '11' { "Verifying" } 
                       '12' { "InstallComplete" } 
                       '13' { "Error" } 
                       '14' { "WaitServiceWindow" } 
                       '15' { "WaitUserLogon" } 
                       '16' { "WaitUserLogoff" } 
                       '17' { "WaitJobUserLogon" } 
                       '18' { "WaitUserReconnect" } 
                       '19' { "PendingUserLogoff" } 
                       '20' { "PendingUpdate" } 
                       '21' { "WaitingRetry" } 
                       '22' { "WaitPresModeOff" } 
                       '23' { "WaitForOrchestration" } 
 
 
                       DEFAULT { "Unknown" }
               }
 
               $Object = New-Object PSObject -Property ([ordered]@{      
                       ArticleId         = $App.ArticleID
                       Publisher         = $App.Publisher
                       Software          = $App.Name
                       Description       = $App.Description
                       State             = $EvState
                       StartTime         = Get-Date ([system.management.managementdatetimeconverter]::todatetime($($App.StartTime)))
                       DeadLine          = if($App.Deadline -ne $null) {Get-Date ([system.management.managementdatetimeconverter]::todatetime($($App.Deadline)))}
                        
               })
 
               $Object
           }
       }
 
   } -ErrorAction Stop | select @{n='ServerName';e={$_.pscomputername}},ArticleID,Publisher,Software,Description,State,StartTime,DeadLine
}
Catch [System.Exception]{
   Write-Host "Error" -BackgroundColor Red -ForegroundColor Yellow
   $_.Exception.Message
}
 
#Display results
$Updates | Out-GridView -Title "Updates"

#Export results to CSV
$Updates | Export-Csv ".\updatesserverlist.csv" -Force -NoTypeInformation

#Install Update
Foreach ($Upapp in $Updates)
   {
       if ($Upapp.State -eq "None") {
           Write-Host $Upapp.ServerName 
           Write-Host $Upapp.State 
           $st = "KB"
           $st = $st + $Upapp.ArticleId
           Write-Host $st 
           trigger-AvailableSupInstall -Computername $Upapp.ServerName -SupName $st 
       }
       
   }
