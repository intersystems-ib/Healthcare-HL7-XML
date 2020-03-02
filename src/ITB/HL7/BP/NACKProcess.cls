/// 
Class ITB.HL7.BP.NACKProcess Extends Ens.BusinessProcess [ ClassType = persistent, ProcedureBlock ]
{

/// Name of production element that sent the original HL7 message
Property Target As %String(MAXLEN = 200);

/// Comma separated list of NACK Codes that will be considered errors
Property NACKCodes As %String [ InitialExpression = "AE" ];

/// Allow more than one error entry (NACK) with the same MSHCControlID and Target.
Property AllowDuplicates As %Boolean [ InitialExpression = "0" ];

Property SearchTableClass As %String(MAXLEN = 128) [ InitialExpression = "EnsLib.HL7.SearchTable" ];

Parameter SETTINGS = "NACKCodes,Target,SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.HL7.Service.Standard},-ThrottleDelay,ReplyCodeActions,RetryInterval,AlertRetryGracePeriod:Alerting,FailureTimeout,QueueCountAlert:Alerting,QueueWaitAlert:Alerting";

/// Handle a 'Request'
Method OnRequest(request As %Library.Persistent, Output response As %Library.Persistent) As %Status
{
	set ret = $$$OK
	try {
		set tNumRows="", tIdList=""
		set tSC = ##class(ITB.HL7.Data.NACK).InsertError(..%PrimaryRequestHeader, request, ..Target, ..NACKCodes, ..SearchTableClass, ..AllowDuplicates, .tNumRows, .tIdList)
		do ..AfterInsertError(request, tSC, tNumRows, tIdList)
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit $$$OK
}

/// Method that will be executed after calling ##class(ITB.HL7.Data.NACK).InsertError.
/// Can be overriden and be used to add specific behaviour (e.g: generate an alert with some content from ERR segment of pRequest).
/// request: Message (NACK) received by Business Process.
/// tSC: Status code returned by ##class(ITB.HL7.Data.NACK).InsertError.
/// pNumRows: Number of rows inserted in ITB.HL7.Data.NACK.
/// pIdList: List with IDs inserted in ITB.HL7.Data.NACK.
Method AfterInsertError(request As EnsLib.HL7.Message, tSC As %Status, pNumRows As %String, pIdList As %ListOfDataTypes) As %Status
{
	set ret = $$$OK
	try {
		// add your custom code here
	} catch ex {
		set ret = ex.AsStatus()
		$$$LOGERROR($system.Status.GetOneErrorText(ret))
	}
	quit ret
}

Storage Default
{
<Data name="NACKProcessDefaultData">
<Subscript>"NACKProcess"</Subscript>
<Value name="1">
<Value>Target</Value>
</Value>
<Value name="2">
<Value>NACKCodes</Value>
</Value>
<Value name="3">
<Value>SearchTableClass</Value>
</Value>
<Value name="4">
<Value>AllowDuplicates</Value>
</Value>
</Data>
<DefaultData>NACKProcessDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
