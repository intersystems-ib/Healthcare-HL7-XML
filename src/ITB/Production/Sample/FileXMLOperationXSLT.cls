/// 
/// This is an simple example of an operation that transforms HL7 XML using XSLT before sending the message
/// See ITB.Production.Sample.SimpleXSLT for XSLT sample.
Class ITB.Production.Sample.FileXMLOperationXSLT Extends ITB.HL7.BO.FileXMLOperation
{

/// Class name which contains an XData block with XSLT
Property XSLTClass As %String(MAXLEN = 255);

/// Name of the XData block which contains XSLT
Property XSLTXData As %String(MAXLEN = 255);

Parameter SETTINGS = "XSLTClass:XSLT,XSLTXData:XSLT";

/// Handle XML before sending. This method can be overridden to perform transformations in XML before sending message.
Method HandleXMLBeforeSending(pXML As %Stream.Object, Output pXMLToSend As %Stream.Object) As %Status
{
	set ret = $$$OK
    try {
        set pXMLToSend = ##class(%Stream.GlobalCharacter).%New()
       
        // open XSLT XData
        Set tXSLT = ##class(%Dictionary.CompiledXData).%OpenId(..XSLTClass_"||"_..XSLTXData).Data
        // transform XML using XSLT
        $$$ThrowOnError(##class(%XML.XSLT.Transformer).TransformStream(pXML, tXSLT, .pXMLToSend))

    } catch ex {
        set ret = ex.AsStatus()
    }
    quit ret
}

}
