/// Business Service that receives HL7 (XML) through TCP (MLLP) and sends it as EnsLib.HL7.Message 
/// to targets returning the corresponding Ack (XML) to source
Class ITB.HL7.BS.TCPXMLService Extends ITB.HL7.BS.XMLService
{

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id$";

Parameter ADAPTER = "ITB.TCP.FramedInboundAdapter";

Method OnProcessInput(pInput As %Stream.Object, Output pOutput As %Stream.Object) As %Status
{
	set ret = $$$OK
	
	try {
		$$$THROWONERROR(tSC, ..StreamProcessInput(pInput, .pOutput, 1))
	} catch ex {
		set ret = ex.AsStatus()
	}
	
	quit ret
}

}
