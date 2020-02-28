/// Standard HL7 ER7 Operation that has been extended to enable extra settings (e.g. NACKControl)
Class ITB.HL7.BO.TCPOperation Extends EnsLib.HL7.Operation.TCPOperation
{

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id$";

/// Enable NACK control. A SearchTable MUST be used. Configure a Service to receive async NACK messages and process them in ITB.HL7.BP.NACKProcess
Property NACKControl As %Boolean [ InitialExpression = 0 ];

Parameter SETTINGS = "NACKControl,ReplyCodeActions,NoFailWhileDisconnected,SaveReplies";

Method SendMessage(pMsgOut As EnsLib.HL7.Message, Output pMsgIn As EnsLib.HL7.Message, pExpectedSequenceNumber As %String) As %Status
{
	set tSC = ##super(pMsgOut,.pMsgIn,pExpectedSequenceNumber)
	
	try {
		if ..NACKControl {
			do ##class(ITB.HL7.Data.NACK).RemoveError(pMsgOut,..%RequestHeader.TargetConfigName)
		}
	} catch ex {
		$$$LOGERROR($system.Status.GetOneErrorText(ex.AsStatus()))
	}
	
	quit tSC
}

}
