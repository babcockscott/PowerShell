function Get-ComputerSite ($ComputerName){
   $ComputerName = "$env:computername.$env:userdnsdomain"
   $site = nltest /server:$ComputerName /dsgetsite 2>$null
   if($LASTEXITCODE -eq 0){ $site[0] }
}