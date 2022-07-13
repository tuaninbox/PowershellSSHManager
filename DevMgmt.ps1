# Device Management Script
# Author: Tuan Hoang
# Version: 0.1

############# Read-Config ###############
function Read-Config {
    get-content DevMgmt.ini | foreach-object {
        $iniData = @{}
        $iniData[$_.split('=')[0]] = $_.split('=')[1]
        $iniData
    }

    $iniData.certname
}
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
  
############# Import-Cert ###############
function Import-Cert {
    try {
        $certpass = Get-Credential -UserName tuan.hoang -Message "Password to import certificate"
        Import-PfxCertificate -FilePath $pfxfile -CertStoreLocation Cert:\CurrentUser\my -Password $certpass.Password
    }
    catch {
        Write-Host $_
        timeout /t -1
    }
}

############# Encrypt-DataUsingCert ##############
function Encrypt-DataUsingCert {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Data
    )

$e=Protect-CmsMessage -To cn=$certname -Content $Data
Write-Host $e

$ue = Unprotect-CmsMessage -Content $e -IncludeContext
Write-Host $ue

return $e

}


######### Decrypt-DataUsingCert ##################
function Decrypt-DataUsingCert {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$SecureData
    )

    $p = Unprotect-CmsMessage -Content $SecureData -IncludeContext
    return $p
}

############# Menu #########################
function Print-Menu1 {
    [CmdletBinding()]
    param(
        [Parameter()]
        $Data
    )
    
    Clear
    Write-Host "####################### DEVICE MANAGEMENT #######################"
    $Data | foreach {
        Write-Host $_.No"." $_.Name, $_.Description, $_.IP
    }
    Write-Host "-----------------------------------------------------------------"
    Write-Host "A . Add Credential"
    Write-Host "V . View Credential"
    Write-Host "R . Remove Credential"
    Write-Host "Q . Quit"
    Write-Host "#################################################################"
    Write-Host
    $r=Read-Host "Select an option"
    return $r
}

function Print-Menu {
    Clear
    # Use this site (https://ozh.github.io/ascii-tables/) to generate menu below
    $menu="
+----------------+----------------+----------------+----------------+
|    Switches    |     Routers    |    Firewalls   | Load Balancers |
+----------------+----------------+----------------+----------------+
| 1. Switch 1    | 30. Router 1   | 40. Firewall 1 | 50. LB 1       |
| 2. Switch 2    | 31. Router 2   | 41. Firewall 2 | 51. LB 2       |
| 3. Switch 3    | 32. Router 3   | 42. Firewall 3 |                |
+----------------+----------------+----------------+----------------+"

    Write-Host $menu
    Write-Host "| A . Add Credential                                                |"
    Write-Host "| V . View Credential                                               |"
    Write-Host "| R . Remove Credential                                             |"
    Write-Host "| Q . Quit                                                          |"
    Write-Host "+-------------------------------------------------------------------+"
    Write-Host
    $r=Read-Host "Select an option"
    return $r
}

############ Connection #####################
function Connect-Device {
    [CmdletBinding()]
    param(
        [Parameter()]
        $Device
    )
    [xml]$CredDB = Get-Content -Path $credfile
    $cred = $CredDB.Credentials.Credential | Where-Object Name -eq $Device.cred
    #Write-Host $cred.SecureUser, $cred.SecurePassword

    $username = Decrypt-DataUsingCert -SecureData $cred.SecureUser.Trim()
    $password = Decrypt-DataUsingCert -SecureData $cred.SecurePassword.Trim()
    Write-Host "Connecting to" $Device.Description "-" $Device.Name "-" $Device.IP
    $add=$Device.IP

    start-process $sshcmd -ArgumentList "$username@$add -pw $password"
}

################ EXIT ##############
function Exit-Program {
    $certname
    Get-ChildItem Cert:\CurrentUser\My -DnsName $certname | Remove-Item
    Write-Host "Key Clear!"
    timeout /t 3
    Exit
}

################# ADD Credential ################
function Add-Credential {
    Write-Host "Credential to Add to Database?"
    $n = Read-Host "Name"
    $d = Read-Host "Description"
    $u = Read-Host "Username"
    $p = Read-Host "Password "

    $su = Encrypt-DataUsingCert -Data $u
    $sp = Encrypt-DataUsingCert -Data $p

    $xmlDoc = [System.Xml.XmlDocument](Get-Content $credfile);
    $cred = $xmlDoc.Credentials.Credential | Where-Object Name -eq $n
    if ($cred -eq $null){
        $newXmlCredential = $xmlDoc.Credentials.AppendChild($xmlDoc.CreateElement("Credential"));
        $newXmlCredential.SetAttribute(“Name”,$n);
        #$newXmlName = $newXmlCredential.AppendChild($xmlDoc.CreateElement("Name"));
        #$newXmlNameTextNode = $newXmlName.AppendChild($xmlDoc.CreateTextNode($n));
        $newXmlDescription = $newXmlCredential.AppendChild($xmlDoc.CreateElement("Description"));
        $newXmlDescriptionTextNode = $newXmlDescription.AppendChild($xmlDoc.CreateTextNode($d));
        $newXmlSecureUser = $newXmlCredential.AppendChild($xmlDoc.CreateElement("SecureUser"));
        $newXmlSecureUserTextNode = $newXmlSecureUser.AppendChild($xmlDoc.CreateTextNode($su));
        $newXmlSecurePassword = $newXmlCredential.AppendChild($xmlDoc.CreateElement("SecurePassword"));
        $newXmlSecurePasswordTextNode = $newXmlSecurePassword.AppendChild($xmlDoc.CreateTextNode($sp));

    $xmlDoc.Save($credfile);
    Write-Host "Credential Save!"
    }
    Else{
        Write-Host "Credential Name Exists"
    }
}

###################### View Credential ###########
function View-Credential {
    [xml]$CredDB = Get-Content -Path $credfile
    $creds = $CredDB.Credentials.Credential
    Write-Host "These are credentials:"
    $creds | foreach {
        Write-Host $_.Name
    }

    $a = Read-Host "Credential to view"

    $cred = $CredDB.Credentials.Credential | Where-Object Name -eq $a
    #Write-Host $cred.Name
    $username = Decrypt-DataUsingCert -SecureData $cred.SecureUser.Trim()
    Write-Host $username
    $password = Decrypt-DataUsingCert -SecureData $cred.SecurePassword.Trim()
    
    #$a = Read-Host "View or Copy Password" 
    $securedValue = Read-Host -AsSecureString "View or Copy Password"
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securedValue)
    $a = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    if ($a -eq "V" -or $a -eq "v"){
        Write-Host $password
        timeout /t 10
    }
    elseif ($a -eq "C" -or $a -eq "c"){
        Set-Clipboard $password
        Write-Host "Password copied to clipboard!"
        timeout /t 3
    }
    else{
        Write-Host "Wrong choice!"
    }
}

###################### Remove Credential ###########
function Remove-Credential {
    [xml]$CredDB = Get-Content -Path $credfile
    $creds = $CredDB.Credentials.Credential
    Write-Host "These are credentials:"
    $creds | foreach {
        Write-Host $_.Name
    }

    $n = Read-Host "Credential to remove"

   
    $a = Read-Host "Are you sure? [Y/N]" 
   
    if ($a -eq "Y" -or $a -eq "y"){
        $xmlDoc = [System.Xml.XmlDocument](Get-Content $credfile);
        $node = $xmlDoc.SelectSingleNode("//credential[@name=$n]")
        $node.ParentNode.RemoveChild($node) | Out-Null
        $xmlDoc.Save($credfile)
        Write-Host "Credential Removed!"
    }
}


################ MAIN ############

############# Variable ##############
$config = Parse-IniFile("devmgmt.ini")
$folder = $config["CONFIG"]["folder"]
$sshcmd = $config["CONFIG"]["sshcmd"]
$pfxfile = $folder + "\" + $config["CONFIG"]["pfxfile"]
$certname = $config["CONFIG"]["certname"]
$credfile = $folder + "\" + $config["CONFIG"]["credfile"]
$devicefile = $folder + "\" + $config["CONFIG"]["devicefile"]

Import-Cert
$devices = Import-Csv $devicefile

While ($True){
    $r = Print-Menu -Data $devices
    ### For System that is not restricting language mode
    #[Environment]::SetEnvironmentVariable('ScriptStart',(Get-Date -Format 'dd/MM/yyyy HH:mm:ss'),[System.EnvironmentVariableTarget]::User)
    #[Environment]::GetEnvironmentVariable('ScriptStart',[System.EnvironmentVariableTarget]::User)
    ### For System that is restricting language mode -> use file
    Get-Date -Format 'dd/MM/yyyy HH:mm:ss' | Out-file ScriptStart.txt
    $s=[DateTime]::ParseExact((Get-Content ScriptStart.txt), 'dd/MM/yyyy HH:mm:ss', $null)
    if ($r -eq "q" -or $r -eq "Q"){
        ### For System that is not restricting language mode
        #[Environment]::SetEnvironmentVariable('ScriptStart',$null,"User")
        ### For System that is restricting language mode -> use file
        Remove-Item ScriptStart.txt -Force
        Exit-Program
    }
    elseif ($r -eq "a" -or $r -eq "A"){
        Add-Credential
    }
    elseif ($r -eq "v" -or $r -eq "V"){
        View-Credential
    }
    elseif ($r -eq "r" -or $r -eq "R"){
        Remove-Credential
    }
    else {
        $devices | foreach {
            if ($r -eq $_.No) {
                Connect-Device -Device $_
                $match=1
                
            }
            else {$match=0}
        }
    }
    if ($match -eq 0){ Write-Host "Invalid Input" }
    timeout /t 2
}