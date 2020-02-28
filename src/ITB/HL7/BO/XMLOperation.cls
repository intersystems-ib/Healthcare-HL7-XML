/// HL7 XML operations common class
Class ITB.HL7.BO.XMLOperation Extends ITB.HL7.BO.XMLReplyStandard
{

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id$";

/// Enable NACK control. A SearchTable MUST be used. Configure a Service to receive async NACK messages and process them in ITB.HL7.BP.NACKProcess
Property NACKControl As %Boolean [ InitialExpression = 0 ];

/// Strip namespace in HL7 XML.
Property StripNamespace As %Boolean [ InitialExpression = 1 ];

Parameter SETTINGS = "StripNamespace,NACKControl,SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.HL7.Service.Standard},MessageSchemaCategory:Basic:selector?context={Ens.ContextSearch/SchemaCategories?host=EnsLib.HL7.Service.Standard}";

/// Send EnsLib.HL7.Message as XML
Method SendHL7XML(pRequest As EnsLib.HL7.Message, Output pResponse As EnsLib.HL7.Message, pGetAck As %Boolean = 0) As %Status
{
	set ret = $$$OK
	
	try {
		if pRequest.DocType="" {
			set pRequest.DocType = ##class(ITB.HL7.Util.Convert).CalculateDocType(pRequest,..MessageSchemaCategory)
		}
		
		// index HL7 in SearchTable
		if ..SearchTableClass'="" {
			set tSC = $zobjclassmethod(..SearchTableClass,"IndexDoc",pRequest)
			if $$$ISERR(tSC) $$$LOGERROR("SearchTableClass Error: "_##class(%SYSTEM.Status).GetErrorText(tSC))
		}
		
		// convert EnsLib.HL7.Message to XML
		set tXML = ##class(ITB.HL7.Util.Convert).ER7ToXML(pRequest,.tSC,..MessageSchemaCategory,,,..StripNamespace)
		if $$$ISERR(tSC) $$$ThrowStatus(tSC)
		
		// send XML through adapter
		set tAckXML = ##class(%Stream.GlobalCharacter).%New()
		$$$THROWONERROR(tSC, ..AdapterSendStream(tXML,.tAckXML))
		
		if pGetAck {
			// show received XML
			$$$TRACE(tAckXML.Read())
			do tAckXML.Rewind()
			
			// convert received XML ack to ER7
			set tReplyDoc = ##class(ITB.HL7.Util.Convert).XMLToER7(tAckXML,.tSC,..MessageSchemaCategory)
			if $$$ISERR(tSC) $$$ThrowStatus(tSC)
			
			set tReplyDoc.OriginalDocId=pRequest.%Id()
			set tReplyTypeName=tReplyDoc.Name, tReplyCategory=$s(""'=pRequest.MessageTypeCategory:pRequest.MessageTypeCategory,1:$P(pRequest.DocType,":"))
			
			do ##class(EnsLib.HL7.Schema).ResolveReplyNameAndDocType(tReplyCategory_":"_pRequest.Name,.tReplyDocName,.tReplyDocType,0)
			$$$TRACE("Got reply message "_tReplyDoc_" of type "_tReplyTypeName_$S(tReplyTypeName=tReplyDocName:"",1:", expected type "_tReplyDocName))
			set tReplyDoc.IsMutable=0
			kill ..%ActionHint  Set ..%ActionHint("AckType")=tReplyTypeName, ..%ActionHint("ReplyDocName")=tReplyDocName, ..%ActionHint("MsgType")="HL7"
			
			set pResponse = tReplyDoc
		}
		
		if ..NACKControl {
			set tSC = ##class(ITB.HL7.Data.NACK).RemoveError(pRequest,..%RequestHeader.TargetConfigName)
		}
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	
	quit ret
}

/// Send stream using Adapter (this method should be overwritten in derived operations)
Method AdapterSendStream(pRequest As %Stream.Object, Output pResponse As %Stream.Object) As %Status
{
}

/// Return an array of connections for drawing lines on the config diagram
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	do ##super(.pArray,pItem)
	if pItem.GetModifiedSetting("TargetConfigNames",.tValue) {
		for i=1:1:$L(tValue,",") { 
			set tOne=$zstrip($p(tValue,",",i),"<>W")
			continue:""=tOne
			set pArray(tOne)="" 
		}
	}
}

}
