/// HL7 XML services common class
Class ITB.HL7.BS.XMLService Extends (Ens.BusinessService, ITB.HL7.XMLHost)
{

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id$";

Property UseAckCommitCodes As %Boolean [ InitialExpression = 1 ];

Property BadMessageHandler As %String(MAXLEN = 1000);

/// Name of the element to send the incoming XML stream received by this Service if message is processed OK
Property XMLInputHandler As %String(MAXLEN = 1000);

/// Colon-separated LocalFacility:LocalApplication:MessageStructure codes representing this (receiving) facility, application, returning MessageStructure, AcceptAcknowledgmentType and ApplicationAcknowledgmentType<br/>
/// These are used in constructing reply ACK message headers as SendingFacility, SendApplication and MessageStructure. <br/>
/// The '@' symbol represents using the corresponding field from the incoming message. <br/>
/// If your ID must contain a literal @ symbol, escape it with backslash: '\@'
Property LocalFacilityApplication As %String [ InitialExpression = "ISC:EnsembleHL7:ACK:NE:NE" ];

/// Strip namespace in HL7 XML (ACK message).
Property StripNamespace As %Boolean [ InitialExpression = 1 ];

/// Control of ACK handling; options: <br/>
/// - Never : Do not send back any ACK <br/>
/// - Immediate : Send back (commit) ACK reply message immediately upon receipt of the inbound message <br/>
/// - Application : If message passes validation, wait for ACK from target config item and forward it back when it arrives <br/>
Property AckMode As %String(DISPLAYLIST = ",Never,Immediate,Application", VALUELIST = ",Never,Immed,App") [ InitialExpression = "Immed", Required ];

/// Names the target(s) from which an ACK response should be forwarded back to the caller, if the AckMode="Application". 
Property ResponseFrom As %String(MAXLEN = 1000);

Parameter SETTINGS = "StripNamespace,LocalFacilityApplication,AckMode,ResponseFrom::selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},UseAckCommitCodes,TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},BadMessageHandler:Basic:selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},XMLInputHandler:Basic:selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.HL7.Service.Standard},MessageSchemaCategory:Basic:selector?context={Ens.ContextSearch/SchemaCategories?host=EnsLib.HL7.Service.Standard},AlertGracePeriod:Alerting";

/// HL7 XML (Stream) process input
Method StreamProcessInput(pInput As %Stream.Object, Output pOutput As %Stream.Object, pSendAck As %Boolean = 0, pCallTargets As %Boolean = 1, Output pER7 As EnsLib.HL7.Message) As %Status
{
	set ret = $$$OK
	
	try {
		// convert XML input to ER7
		set tER7 = ##class(ITB.HL7.Util.Convert).XMLToER7(pInput,.tSC,..MessageSchemaCategory)
		if $$$ISERR(tSC) $$$ThrowStatus(tSC)
		set pER7 = tER7
		
		// send ACK
		if pSendAck,..AckMode="Immed" {
			set tAckCode = $case(..UseAckCommitCodes, 1:"CA", 0:"AA")
			set tAckER7 = ..GetAck(tER7, tAckCode)
			set tAckXML = ##class(ITB.HL7.Util.Convert).ER7ToXML(tAckER7,.tSC,,,,..StripNamespace)
			if $$$ISERR(tSC) $$$ThrowStatus(tSC)
			set pOutput = tAckXML
		}
		
		// send EnsLib.HL7.Message to targets
		if pCallTargets {
			for i=1:1:$l(..TargetConfigNames, ",") { 
				set tTarget=$zstrip($p(..TargetConfigNames,",",i),"<>W")
				if pSendAck,..AckMode="App",..ResponseFrom=tTarget {
					$$$THROWONERROR(tSC,..SendRequestSync(tTarget, tER7, .tAckER7))
					set tAckXML = ##class(ITB.HL7.Util.Convert).ER7ToXML(tAckER7,.tSC,,,,..StripNamespace)
					if $$$ISERR(tSC) $$$ThrowStatus(tSC)
					set pOutput = tAckXML
				} else {
					$$$THROWONERROR(tSC,..SendRequestAsync(tTarget, tER7))
				}
			}
		}
		
		// index HL7 in SearchTable
		if ..SearchTableClass'="" {
			set tSC = $zobjclassmethod(..SearchTableClass,"IndexDoc",tER7)
			if $$$ISERR(tSC) $$$LOGERROR("SearchTableClass Error: "_##class(%SYSTEM.Status).GetErrorText(tSC))
		}
		
		// ok. send XML input to XMLInputHandler if any
		do:..XMLInputHandler'="" ..SendStreamToTarget(..XMLInputHandler,pInput)
		
	} catch ex {
		set ret = ex.AsStatus()
		$$$LOGERROR($$$StatusDisplayString(ret))
		
		// error occured. send service input to BadMessageHandler if any
		do:..BadMessageHandler'="" ..SendStreamToTarget(..BadMessageHandler,pInput)
		
		// send alert when HL7 XML has not been processed correctly
		do:..AlertOnError ..SendAlert(##class(Ens.AlertRequest).%New($LB(..%ConfigName,$$$StatusDisplayString(ret))))
	}
	
	quit ret
}

/// Get ACK message for a given HL7 message
Method GetAck(pMsg As EnsLib.HL7.Message, pReplyCode As %String) As EnsLib.HL7.Message
{
	// create ACK and copy the control id to the ack control id
	set tReply = pMsg.NewReplyDocument(,..LocalFacilityApplication)
	set tReply.Source = pMsg.%Id()
	do tReply.SetValueAt(pMsg.GetValueAt("1:10"),"1:10")
	do tReply.SetValueAt($p(..LocalFacilityApplication,":",3),"1:9.3")
	do tReply.SetValueAt($p(..LocalFacilityApplication,":",4),"1:15")
	do tReply.SetValueAt($p(..LocalFacilityApplication,":",5),"1:16")
	
	// MSA segment
	set tMSA=##class(EnsLib.HL7.Segment).%New($LB("",1))
	set tMSA.Separators=tReply.Separators
	do tMSA.SetValueAt("MSA",0)
	do tMSA.SetValueAt(pReplyCode,1)
	do tMSA.SetValueAt(pMsg.GetValueAt("1:10"),2)
	do tReply.AppendSegment(tMSA)
	
	quit tReply
}

/// Send pInput stream to a production target
Method SendStreamToTarget(pTarget As %String, pInput As %Stream.Object) As %Status
{
	set tMsg = ##class(Ens.StreamContainer).%New(pInput)
	set tSC = ..SendRequestAsync(pTarget, tMsg)
	if $$$ISERR(tSC) $$$LOGERROR(##class(%SYSTEM.Status).GetOneErrorText((tSC)))
	quit tSC
}

/// Return an array of connections for drawing lines on the config diagram
ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	do ##super(.pArray,pItem)
	
	if pItem.GetModifiedSetting("TargetConfigNames",.tValue) {
		
		set:pItem.GetModifiedSetting("BadMessageHandler",.tBadMessageHandler) tValue=tValue_","_tBadMessageHandler
		set:pItem.GetModifiedSetting("XMLInputHandler",.tXMLInputHandler) tValue=tValue_","_tXMLInputHandler
		
		for i=1:1:$L(tValue,",") { 
			set tOne=$zstrip($p(tValue,",",i),"<>W")
			continue:""=tOne
			set pArray(tOne)="" 
		}
	}
}

}
