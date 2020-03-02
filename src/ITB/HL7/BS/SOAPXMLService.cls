/// WebService that receives HL7 (XML) and sends it as EnsLib.HL7.Message 
/// to targets returning the corresponding Ack (XML) to source.
/// Override and modify this service as needed.
Class ITB.HL7.BS.SOAPXMLService Extends (EnsLib.SOAP.Service, ITB.HL7.BS.XMLService) [ ProcedureBlock ]
{

/// The SOAP name of this service.
Parameter SERVICENAME = "HL7SOAPXMLService";

/// SOAP Namespace for the WebService
Parameter NAMESPACE = "http://tempuri.org";

/// acceptMessage
Method AcceptMessage(input As %String) As %String [ WebMethod ]
{
	set output=""
	try {
		$$$THROWONERROR(tSC,..OnProcessInput(input, .output))
	} catch ex {
		set tSC = ex.AsStatus()
		$$$LOGERROR(##class(%SYSTEM.Status).GetOneErrorText(tSC))
	}
	quit output
}

/// Override this method to process incoming data. Do not call SendRequestSync/Async() from outside this method (e.g. in a SOAP Service or a CSP page).
Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject, ByRef pHint As %String) As %Status
{
	set ret = $$$OK
	set pOutput=""
	try {
		// string to stream
		set pInputStream = ##class(%Stream.GlobalCharacter).%New()
		do pInputStream.Write($zcvt(pInput,"O","UTF8"))
		
		// convert incoming HL7 (xml) to ER7
		set tOutput = ##class(%Stream.GlobalCharacter).%New()
		set tSC = ..StreamProcessInput(pInputStream, .tOutput, 1, 1, .tReqER7)
		if $$$ISERR(tSC) $$$ThrowStatus(tSC)
		
		// ack
		if $isobject(tOutput) {
			set pOutput=tOutput.Read()
		}
	} catch ex {
		set ret = ex.AsStatus()
		$$$LOGERROR(##class(%SYSTEM.Status).GetOneErrorText(ret))
	}
	quit ret
}

}
