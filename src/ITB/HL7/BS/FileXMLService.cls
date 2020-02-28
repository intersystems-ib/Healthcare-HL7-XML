/// Business Service that reads a HL7 (XML) file and sends it as EnsLib.HL7.Message to targets
Class ITB.HL7.BS.FileXMLService Extends ITB.HL7.BS.XMLService
{

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id$";

Parameter ADAPTER = "EnsLib.File.InboundAdapter";

Method OnProcessInput(pInput As %Stream.Object, Output pOutput As %Stream.Object) As %Status
{
	set ret = $$$OK
	
	try {
		$$$THROWONERROR(tSC, ..StreamProcessInput(pInput, .pOutput, 0))
	} catch ex {
		set ret = ex.AsStatus()
	}
	
	quit ret
}

}
