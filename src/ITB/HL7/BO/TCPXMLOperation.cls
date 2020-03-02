/// Business Operation that receives an EnsLib.HL7.Message and sends it as HL7 (XML) 
/// through TCP (MLLP) returning received ACK as EnsLib.HL7.Message
Class ITB.HL7.BO.TCPXMLOperation Extends ITB.HL7.BO.XMLOperation
{

Parameter ADAPTER = "ITB.TCP.FramedOutboundAdapter";

Property Adapter As ITB.TCP.FramedOutboundAdapter;

Parameter INVOCATION = "Queue";

/// Send EnsLib.HL7.Message
Method SendHL7(pRequest As EnsLib.HL7.Message, Output pResponse As EnsLib.HL7.Message) As %Status
{
	set ret = $$$OK
	
	try {
		$$$THROWONERROR(tSC, ..SendHL7XML(pRequest, .pResponse, 1))
	} catch ex {
		set ret = ex.AsStatus()
	}
	
	quit ret
}

/// Send stream using Adapter (this method should be overwritten in derived operations)
Method AdapterSendStream(pRequest As %Stream.Object, Output pResponse As %Stream.Object) As %Status
{
	quit ..Adapter.SendMessageStream(pRequest,.pResponse)
}

XData MessageMap
{
<MapItems>
	<MapItem MessageType="EnsLib.HL7.Message"> 
		<Method>SendHL7</Method>
	</MapItem>
</MapItems>
}

}
