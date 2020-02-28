/// Standard HL7 ER7 TCP Service that has been extended to enable extra behaviour (e.g. LocalFacilityApplication)
Class ITB.HL7.BS.TCPService Extends EnsLib.HL7.Service.TCPService
{

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id$";

/// Colon-separated LocalFacility:LocalApplication:MessageStructure codes representing this (receiving) facility, application, returning MessageStructure, AcceptAcknowledgmentType and ApplicationAcknowledgmentType<br/>
/// These are used in constructing reply ACK message headers as SendingFacility, SendApplication and MessageStructure. <br/>
/// The '@' symbol represents using the corresponding field from the incoming message. <br/>
/// If your ID must contain a literal @ symbol, escape it with backslash: '\@'
Property LocalFacilityApplication As %String [ InitialExpression = "ISC:EnsembleHL7:ACK:NE:NE" ];

/// Override this method to construct a customized reply document. Inputs are the original document and
///  the reply code and the status code that the framework produced in processing the original document.
///  If you change the status code but do not construct a reply document, the framework will use the new value to construct a standard reply document.
///  If you construct a non-HL7 object it must still have a property called 'Envelope'; Piece:2 of this value will be written verbatim.
Method OnConstructReply(Output pReplyDoc As EnsLib.EDI.Document, pOriginalDoc As EnsLib.EDI.Document, ByRef pReplyCode As %String, ByRef pSC As %Status, pEarlyAck As %Boolean) As %Status
{
	// from EnsLib.HL7.Service.Standard:constructReply
	// ITB+
	Set tSC=pSC
	// ITB-
	If '$D(tReplyDoc) {
		If $Case(pOriginalDoc.Name,"FHS":1,"BHS":1,:0) {
			If "" '= pOriginalDoc.ParentId { ; top doc
				Set tReplyDoc=$$$NULLOREF
			} Else {
				If ..%ForwardBatchWhole=1 { ; no need to check for %ForwardBatchWhole>1 because this is runtime
					#; Make ACKs for all children
					If '$Case(..AckMode,"Byte":1 ,:pEarlyAck<0) {
						Set pSC=pOriginalDoc.GetChildIdsArray(.tChildArray,pOriginalDoc.%Id(),1)
						Set i="" For { Set i=$O(tChildArray(i),1,tChildId)  Quit:""=i
							Set tChild=pOriginalDoc.%OpenId(tChildId)
							Set tRepliesArray=i, tRepliesArray(i)=..constructReply(tChild,$S(..UseAckCommitCodes&&(+tChild.GetValueAt("1:12.1")>=2.3):"C",1:"A")_"A",.pSC,pEarlyAck)  If $$$ISERR(pSC) $$$LOGSTATUS(pSC) Quit
						}
					}
				} Else {
					Merge tRepliesArray=..%ReplyDocuments  Kill ..%ReplyDocuments  Set ..%ReplyDocuments=0
				}
				Set:$$$ISOK(pSC) tReplyDoc=..constructBatchReply(pOriginalDoc,.tRepliesArray,.pSC,pEarlyAck)
			}
		} Else {
			Set tIsErr=("A"'=$E(pReplyCode,2))
			If $Case(..AckMode,"Byte":1, :pEarlyAck<0) {
				Set tReplyDoc=$S(tIsErr:$C($$$SingleByteAckErrorAscii),1:$C($$$SingleByteAckAcceptAscii))
			} Else {
				Set tReplyDoc=pOriginalDoc.NewReplyDocument(,..LocalFacilityApplication)
				Set tReplyDoc.Source=pOriginalDoc.%Id()
				Do:..#UseOriginalControlId tReplyDoc.SetValueAt(pOriginalDoc.GetValueAt("1:10"),"1:10") ; copy the control id to the ack control id
				Set tAckMSA=##class(EnsLib.HL7.Segment).%New($LB("",1))
				Set tAckMSA.Separators=tReplyDoc.Separators
				Do tAckMSA.SetValueAt("MSA",0)
				Do tAckMSA.SetValueAt(pReplyCode,1)
				Do tAckMSA.SetValueAt(pOriginalDoc.GetValueAt("1:10"),2)
				Do:$G($$$ExpectedSequenceNumber) tAckMSA.SetValueAt($$$ExpectedSequenceNumber,4)
				#; Deprecated since v2.1 - Do tAckMSA.SetValueAt($S(pForwardMsg:"D",1:"F"),5//"DelayedAcknowledgmentType")
				Do tReplyDoc.AppendSegment(tAckMSA)
				If ..AddNackERR&&tIsErr {
					// Now build an ERR segment in case of error
					Set tAckERR=##class(EnsLib.HL7.Segment).%New($LB("",1))
					Set tAckERR.Separators=tReplyDoc.Separators
					Do tAckERR.SetValueAt("ERR",0)
					#;Do tAckERR.SetValueAt("207"_tAckERR.CS_"Application internal error",3) 
					Do tAckERR.SetValueAt("E",4)  // It's an error
					Do tAckERR.SetValueAt($P($system.Status.GetErrorCodes(tSC),","),5)
					Do tAckERR.SetValueAt(tAckERR.Escape($$$StatusDisplayString(tSC)),8)
					Do tReplyDoc.AppendSegment(tAckERR)
				}
				
				// ITB+
				do tReplyDoc.SetValueAt($p(..LocalFacilityApplication,":",3),"1:9.3")
				do tReplyDoc.SetValueAt($p(..LocalFacilityApplication,":",4),"1:15")
				do tReplyDoc.SetValueAt($p(..LocalFacilityApplication,":",5),"1:16")
				Set pReplyDoc = tReplyDoc
				// ITB-
				
				Set tReplyDoc.IsMutable=0
			}
		}
	}
	Set:$IsObject(tReplyDoc) tReplyDoc.OriginalDocId=pOriginalDoc.%Id()
	$$$sysTRACE("Constructed reply document '"_tReplyDoc_"' for original document "_pOriginalDoc_" / "_pOriginalDoc.%Id()_" reflecting status: "_$$$StatusDisplayString(tSC))
	Quit $G(tReplyDoc,$$$NULLOREF)
}

}
