/// Business Service that reads a HL7 (XML) sent over HTTP and sends it as EnsLib.HL7.Message to targets
Class ITB.HL7.BS.HTTPXMLService Extends ITB.HL7.BS.XMLService
{

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id$";

Parameter ADAPTER = "EnsLib.HTTP.InboundAdapter";

/// Content Type used to send the HTTP content
Property ContentType As %String [ InitialExpression = "application/hl7-v2+xml" ];

Parameter SETTINGS = "ContentType,UseAckCommitCodes,TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},BadMessageHandler:Basic:selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},XMLInputHandler:Basic:selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.HL7.Service.Standard},MessageSchemaCategory:Basic:selector?context={Ens.ContextSearch/SchemaCategories?host=EnsLib.HL7.Service.Standard},AlertGracePeriod:Alerting";

Method OnProcessInput(pInput As %Stream.Object, Output pOutput As %Stream.Object) As %Status
{
	set ret = $$$OK
	
	try {
		$$$THROWONERROR(tSC, ..StreamProcessInput(pInput, .pOutput, 1))
		set pOutput.Attributes("ResponseCode") = "200 OK"
		set pOutput.Attributes("Content-Type") = ..ContentType
	} catch ex {
		set ret = ex.AsStatus()
		do pOutput.Clear()
		set pOutput.Attributes("ResponseCode")="500 ServerError"
	}
	
	quit ret
}

}
