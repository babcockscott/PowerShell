# This funtion determines the CAS servers in the Exchange organization and then
# tests the server health for the frontend transport service as well as tests 
# the server component state. If both are healthy the server is added to
# an array as a candidate to send mail through. It also makes a determiniation on the
# AD site and prefers the same site as the server in which the function runs from.
# It will choose a server from a remote site if none of the local site CAS server
# transport facilities are healthy or active. The choice of server is random in
# either scenario.
Function Get-RandomTransportService {
	# Determine the AD site in which server running the script is located.
	$AdSite = nltest /server:$env:logonserver /dsgetsite | select -first 1
	# Create empty array to contain healthy CAS servers in local AD site.
	$ServerList = @()
	# Create empty array to contail healthy CAS servers in all other remote AD sites.
	$AltServerList = @()
	# Begin foreach loop for each CAS server and determine health/component state
	# then choose random server to send mail through.
	Get-FrontEndTransportService | foreach {
		# Convert name to string for nltest
		param ([string]$TransportServer = $_.name)
		# Use nltest to determine the local site.
		If ((nltest /server:$TransportServer /dsgetsite | select -first 1) -eq $AdSite) {
			# Test health and component state for transport service. Healthy servers are added to the $ServerList.
			If ((Get-ServerHealth -Identity $TransportServer | Where-Object { $_.name -eq "FrontendTransportServiceRunningMonitor" }).AlertValue -eq "Healthy" -and ((Get-ServerComponentState -Identity $TransportServer -Component FrontendTransport).State -eq "Active")) {
				$ServerList += $_.name
			}
		# Use nltest to determine the if the CAS server is in remote site.
		} ElseIf ((nltest /server:$TransportServer /dsgetsite | select -first 1) -ne $AdSite) {
			# Test health and component state for transport service. Healthy servers are added to the $AltServerList.
			If ((Get-ServerHealth -Identity $TransportServer | Where-Object { $_.name -eq "FrontendTransportServiceRunningMonitor" }).AlertValue -eq "Healthy" -and ((Get-ServerComponentState -Identity $TransportServer -Component FrontendTransport).State -eq "Active")) {
				$AltServerList += $_.name
			}
		}
	}
	# Test if there are servers in $ServerList, then choose a random one.
	If ((($ServerList | measure).count) -ne 0) {
		$Server = $ServerList | Get-Random
	# Otherwise choose a server in a remote site as a last resort.	
	} else {
		$Server = $AltServerList | Get-Random
	}
	# Return the chosen server.
	$Server
}