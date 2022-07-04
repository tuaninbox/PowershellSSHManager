#===== VARIABLES =========
$timeout=30
$configfile="devmgmt.ini"
$programfile="DevMgmt.ps1"
#=========================
if (-not(Test-Path $configfile) -or (-not(Test-Path $programfile))) {
        Write-Host "Configuration file" $configfile "and/or program file" $programfile "does not existed"
        Exit
    }
$p=Start-Process  "powershell" -argumentlist 'c:\powershellSSHmanager\DevMgmt.ps1' -PassThru

### For System that is not restricting language mode
#[Environment]::SetEnvironmentVariable('ScriptStart',(Get-Date -Format 'dd/MM/yyyy HH:mm:ss'),[System.EnvironmentVariableTarget]::User)
#[Environment]::GetEnvironmentVariable('ScriptStart',[System.EnvironmentVariableTarget]::User)
### For System that is restricting language mode -> use file
Get-Date -Format 'dd/MM/yyyy HH:mm:ss' | Out-file ScriptStart.txt
Get-Content ScriptStart.txt
do {
  Start-Sleep 2
  try{
    ### For System that is not restricting language mode
    #$s=[DateTime]::ParseExact([Environment]::GetEnvironmentVariable('ScriptStart',[System.EnvironmentVariableTarget]::User), 'dd/MM/yyyy HH:mm:ss', $null)
    ### For System that is restricting language mode -> use file
    $s=[DateTime]::ParseExact((Get-Content ScriptStart.txt -ErrorAction Stop), 'dd/MM/yyyy HH:mm:ss', $null)
  }
  catch {$s=$null}
  if (!$s){
    Get-Date
    Exit
  }
  $f = Get-Date
  $hr = ($f-$s).hours
  $min = ($f-$s).minutes
  $sec = ($f-$s).seconds
  $t = $hr.toString() + ":" + $min.toString() + ":" + $sec.toString()
  Write-Progress -Activity "Time Elapses $t"
  $elapsedtime = $hr*3600 + $min*60 + $sec
  if ($elapsedtime -gt $timeout) {
        Get-Date
        $p | kill
        ### For System that is not restricting language mode
        #[Environment]::SetEnvironmentVariable('ScriptStart',$null,"User")
        ### For System that is restricting language mode -> use file
        Remove-Item ScriptStart.txt -Force

        Exit
  } #if
} while ($true) 
