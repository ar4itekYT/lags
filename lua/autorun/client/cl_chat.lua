function sendmsg()
	local str = net.ReadString()
	Msg("[Защита]: " .. str .. "\n" )
end

net.Receive("lags_sendmsg", sendmsg)
