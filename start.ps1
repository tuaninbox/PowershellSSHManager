#===== VARIABLES =========
$timeout=3600
$configfile="devmgmt.ini"
$programfile="DevMgmt.ps1"
#=========================

################ EXIT ##############
function Exit-Program {
    $certname
    Get-ChildItem Cert:\CurrentUser\My -DnsName $certname | Remove-Item
    Write-Host "Key Clear!"
    timeout /t 3
    Exit
}

################ Parse Config FIle ################
Function Parse-IniFile ($file) {
    $ini = @{}
  
    # Create a default section if none exist in the file. Like a java prop file.
    $section = "NO_SECTION"
    $ini[$section] = @{}
    if (-not(Test-Path $file)) {
        Write-Host "Configuration file" $file "does not existed"
        Exit
    }
    switch -regex -file $file {
      "^\[(.+)\]$" {
        $section = $matches[1].Trim()
        $ini[$section] = @{}
      }
      "^\s*([^#].+?)\s*=\s*(.*)" {
        $name,$value = $matches[1..2]
        # skip comments that start with semicolon:
        if (!($name.StartsWith(";"))) {
          $ini[$section][$name] = $value.Trim()
        }
      }
    }
    return $ini
  }


if (-not(Test-Path $configfile) -or (-not(Test-Path $programfile))) {
        Write-Host "Configuration file" $configfile "and/or program file" $programfile "does not existed"
        Exit
    }

$config = Parse-IniFile("devmgmt.ini")

$certname = $config["CONFIG"]["certname"]
$folder = $config["CONFIG"]["folder"]
$p=Start-Process  "powershell" -argumentlist $folder\$programfile -PassThru

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
        Exit-Program
  } #if
} while ($true) 
