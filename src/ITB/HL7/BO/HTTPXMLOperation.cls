/// Business Operation that receives an EnsLib.HL7.Message and sends it as HL7 (XML) 
/// over HTTP returning received ACK as EnsLib.HL7.Message
Class ITB.HL7.BO.HTTPXMLOperation Extends ITB.HL7.BO.XMLOperation
{

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id$";

Parameter ADAPTER = "EnsLib.HTTP.OutboundAdapter";

Property Adapter As EnsLib.HTTP.OutboundAdapter;

Parameter INVOCATION = "Queue";

/// Content Type used to send the HTTP content
Property ContentType As %String [ InitialExpression = "application/hl7-v2+xml" ];

Parameter SETTINGS = "ContentType,SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.HL7.Service.Standard},MessageSchemaCategory:Basic:selector?context={Ens.ContextSearch/SchemaCategories?host=EnsLib.HL7.Service.Standard},AlertGracePeriod:Alerting";

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
	set ret = $$$OK
	try {
		set tHttpRequest=##class(%Net.HttpRequest).%New()
		set tHttpRequest.WriteRawMode=1
		set tHttpRequest.ContentType = ..ContentType
		do tHttpRequest.EntityBody.CopyFrom(pRequest)
		set tHttpRequest.ResponseStream=##class(%IO.StringStream).%New()
		
		$$$THROWONERROR(tSC,..Adapter.SendFormDataArray(.tHttpResponse, "Post", tHttpRequest))
		$$$TRACE("Received "_tHttpResponse.Data.Size_" bytes")
		if tHttpResponse.Data.Size {
			set pResponse = ##class(%GlobalCharacterStream).%New()
			do pResponse.CopyFrom(tHttpResponse.Data)
		}
	} catch ex {
		set ret = ex.AsStatus()
	}
	
	quit ret
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
