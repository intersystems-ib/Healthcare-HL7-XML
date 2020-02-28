/// TCP Outbound Adapter that writes framed data (MLLP)
Class ITB.TCP.FramedOutboundAdapter Extends (EnsLib.TCP.OutboundAdapter, ITB.TCP.FramedCommon)
{

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id$";

/// Read out any data in the input buffer before sending output. This ensures that any reply received corresponds to the sent message, and if not looking for replies that the input buffer does not fill up with unexpected junk.
Property FlushBeforeSend As %Boolean [ InitialExpression = 1 ];

Parameter SETTINGS = "FlushBeforeSend:Connection,UseFileStream,PrefixChar,SuffixChar";

Method SendMessageStream(pRequestStream As %Stream.Object, ByRef pResponseStream As %CharacterStream = "%GlobalCharacterStream") As %Status
{
	set tResponseStream=pResponseStream 
	set:'$IsObject(pResponseStream) pResponseStream=$$$NULLOREF
	set tSC=..Connect(..ConnectTimeout)
	
	if $$$ISERR(tSC) { 
		set:$$$StatusEquals(tSC,$$$EnsErrOutConnectExpired,$$$EnsErrOutConnectException) ..BusinessHost.Retry=1  Quit tSC 
	}

	if ..FlushBeforeSend {
		#; Clean out any pending replies left over from earlier messages
		set $ZT="Trap",tJunk0="",tJunkCnt=0
		while 1 {
			read tJunk:0
			quit:""=tJunk
			set tJunkCnt=tJunkCnt+$L(tJunk)
			set:""=tJunk0 tJunk0=tJunk, tJunk=""
		}
		set $ZT=""	
Read
		if tJunkCnt {
			if $$$ISERR(tSC) {
				$$$catTRACE("protocol","Discarding data found in buffer before framed stream send: "_$E(tJunk0,1,1000)_$S($L(tJunk0)>1000||$L(tJunk):"..."_$E(tJunk,*-100,*),1:""))
				$$$ASAVEIOLOGENTRY(tSC,"after framed stream TCP pre-write Read error on "_..IOAddr,$E(tJunk0,1,30000)_$S($L(tJunk0)>30000||$L(tJunk):"..."_$E(tJunk,*-1000,*),1:""))
				quit
			} 
			else {
				if ..GetReply $$$catTRACE("protocol","Discarding data found in buffer before framed stream send: "_$E(tJunk0,1,1000)_$S($L(tJunk0)>1000||$L(tJunk):"..."_$E(tJunk,*-100,*),1:""))
				$$$ASAVEIOLOGENTRY(tSC,"after framed stream TCP pre-write Read on "_..IOAddr,$E(tJunk0,1,30000)_$S($L(tJunk0)>30000||$L(tJunk):"..."_$E(tJunk,*-1000,*),1:""))
			}
			quit:$$$ISERR(tSC)&&..BusinessHost.Retry tSC ; ignore non-disconnect errors : parse errors etc
		}
	} // if FlushBeforeSend
	
	set tCharset=..Charset  
	set:$Case($ZCVT(..Charset,"L"),"default":1,"auto":1,:0) tCharset="UTF-8"
	set:..Connected tSC=..WriteFramedStream(pRequestStream, tCharset)
	
	if $$$ISERR(tSC) {
		if ..IsWriteError(tSC) {
			set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"TCP Framed Write",..IOAddr,$$$StatusDisplayString(tSC))
			set ..BusinessHost.Retry=1  Do ..Disconnect()
		} else {
			if '..StayConnected { Do ..Disconnect() }
			else { Do ..TestConnection() } ; calls Disconnect() if connection is down
		}
		quit tSC
	}
	
	if ..GetReply {
		set tSC=..ReadFramedStream(.tResponseStream, tCharset, ..ResponseTimeout, ..ReadTimeout)
		set:$IsObject(tResponseStream) pResponseStream=tResponseStream
		if $$$ISERR(tSC) {
			if ..IsReadError(tSC) {
				set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"TCP Framed Read", ..IOAddr, $$$StatusDisplayString(tSC))
				set ..BusinessHost.Retry=1 
				do ..Disconnect()
			} 
			else {
				set:$$$StatusEquals(tSC,$$$EnsErrTCPReadTimeoutExpired,$$$EnsErrTCPReadBlockSizeTimeoutExpired) ..BusinessHost.Retry=1
				do ..TestConnection() ; calls Disconnect() if connection is down
			}
		}
	}
	
	do:'..StayConnected&&'..BusinessHost.Retry ..Disconnect()
	quit tSC
	
Trap
	set $ZT="",tSC=$$$SystemError
	if ..IsReadError(tSC) {
		set tSC=$$$ERROR($$$EnsErrOutConnectionLost,"Framed stream pre-write Read",..IOAddr,$$$StatusDisplayString(tSC))
		set ..BusinessHost.Retry=1  do ..Disconnect()
	}
	goto Read
}

}
