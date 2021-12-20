function sendmsg()
	local str = net.ReadString()
	Msg("[Защита]: " .. str .. "\n" )
end

function sendnotify()
	local str = net.ReadString()
	notification.AddLegacy( str, NOTIFY_ERROR, 3 )
	surface.PlaySound( "buttons/button16.wav" )
end

net.Receive("lags_sendmsg", sendmsg)
net.Receive("lags_sendnotify", sendnotify)
