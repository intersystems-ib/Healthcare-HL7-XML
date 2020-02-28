Include ITB

/// HL7 ER7/XML convert methods
/// <example>
/// ; ER7 -> XML
/// set er7=##class(EnsLib.HL7.Message).ImportFromFile("C:\Test\HL7\OMG_O19.hl7")
/// set xml=##class(ITB.HL7.Util.Convert).ER7ToXML(er7,.sc)
/// w xml.Read()
/// do xml.Rewind()
/// ; XML -> ER7
/// set er7=##class(ITB.HL7.Util.Convert).XMLToER7(xml,.sc,"2.5")
/// do er7.OutputToFile("C:\Test\HL7\File.hl7")
/// </example>
Class ITB.HL7.Util.Convert Extends Ens.Rule.FunctionSet
{

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id$";

ClassMethod ER7ToXML(pER7 As EnsLib.HL7.Message, ByRef pSC, pCategory As %String = "", pCode As %String = "", pEvent As %String = "", pStripNamespace As %Boolean = 0) As %Stream
{
	set ret = ##class(%GlobalCharacterStream).%New()
	set pSC = $$$OK
	try {
		if pER7.DocType="" set pER7.DocType=..CalculateDocType(pER7, pCategory, pCode, pEvent)
		if pER7.BuildMapStatus="" $$$THROWONERROR(tSC, pER7.BuildMap())
		set ^||%itb("ER7ToXML","StripNamespace") = pStripNamespace
		
		#if $$$ITB32K
			if pER7.FullSize < $$$CriticalMessageLen {
				do ret.Write(pER7.OutputToString("", "", .pSC, "ITB.HL7.Format.HL7XMLv2"))
			} else {
				$$$ThrowOnError(pER7.OutputToLibraryStream(ret,"","","ITB.HL7.Format.HL7XMLv2"))
			}
		#else
			$$$ThrowOnError(pER7.OutputToLibraryStream(ret,"","","ITB.HL7.Format.HL7XMLv2"))
		#endif
		
	} catch ex {
		set pSC = ex.AsStatus()
	}
	quit ret
}

ClassMethod XMLToER7(pXML As %Stream, ByRef pSC, pCategory As %String = "") As EnsLib.HL7.Message
{
	set ret = ""
	try {
		set ret = ##class(EnsLib.HL7.Message).ImportFromLibraryStream(pXML,.pSC,pCategory,"ITB.HL7.Format.HL7XMLv2")
		if $$$ISERR(pSC) $$$ThrowStatus(pSC)
	
		set ret.DocType = ##class(ITB.HL7.Util.Convert).CalculateDocType(ret,pCategory)
	} catch ex {
		set pSC = ex.AsStatus()
	}
	quit ret
}

ClassMethod CalculateDocType(pMsg As EnsLib.HL7.Message, pCategory As %String = "", pCode As %String = "", pEvent As %String = "") As %String
{
	set:pCategory="" pCategory=pMsg.GetValueAt("1:12")
	set:pCode="" pCode=pMsg.GetValueAt("1:9.1")
	set:pEvent="" pEvent=pMsg.GetValueAt("1:9.2")
	
	// look for Doctype in EnsHL7.Schema
	set docType = $g(^EnsHL7.Schema(pCategory,"MT",pCode_"_"_pEvent))
	
	// handle ACK messages with no EnsHL7.Schema Doctype (e.g. OMG^O19)
	if docType="",pCode="ACK" set docType=pCategory_":ACK"
	
	quit docType
}

}
