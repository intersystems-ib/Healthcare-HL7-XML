/// Business Operation that receives an EnsLib.HL7.Message and writes it on a file as HL7 (XML)
Class ITB.HL7.BO.FileXMLOperation Extends ITB.HL7.BO.XMLOperation
{

Parameter ADAPTER = "EnsLib.File.OutboundAdapter";

Property Adapter As EnsLib.File.OutboundAdapter;

Parameter INVOCATION = "Queue";

/// Send EnsLib.HL7.Message
Method SendHL7(pRequest As EnsLib.HL7.Message, Output pResponse As Ens.Response) As %Status
{
	set ret = $$$OK
	
	try {
		$$$THROWONERROR(tSC, ..SendHL7XML(pRequest, .pResponse, 0))
	} catch ex {
		set ret = ex.AsStatus()
	}
	
	quit ret
}

/// Send stream using Adapter (this method should be overwritten in derived operations)
Method AdapterSendStream(pRequest As %Stream.Object, Output pResponse As %Stream.Object) As %Status
{
	set tFilename = $tr($tr($zdt($h,3),"-:","")," ","_")_".xml"
	quit ..Adapter.PutStream(tFilename, pRequest)
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
