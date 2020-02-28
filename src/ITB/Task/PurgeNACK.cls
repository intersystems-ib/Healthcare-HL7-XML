/// System task to purge NACK messages that reference non-existing Ens.MessageHeader
Class ITB.Task.PurgeNACK Extends %SYS.Task.Definition
{

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id: //custom_ccrs/_common/tools/Iberia/ITB/latest/cls/ITB/Task/PurgeNACK.xml#1 $";

Parameter TaskName = "ITB.Task.PurgeNACK";

/// The OnTask() method is called to execute the task
Method OnTask() As %Status
{
	set ret = $$$OK
	try {
		do ..Log("=====================================")
		do ..Log("*PurgeNACK Begin")
		$$$ThrowOnError(..DeleteNACKTask())
		do ..Log("*PurgeNACK End")
	} catch ex {
		set ret = ex.AsStatus()
		do ..Log("<ERROR> OnTask: "_$system.Status.GetOneErrorText(ret))
	}
	quit ret
}

/// Loop over NACK table and delete any entry that references a non-existing Ens.MessageHeader (OriginalId)
ClassMethod DeleteNACKTask() As %Status
{
	set ret = $$$OK
	try {
		set (ntotal, ndeleted) = 0
		set originalId = ""
		&sql(
		DECLARE cNack CURSOR FOR
		SELECT OriginalId INTO :originalId FROM ITB_HL7_Data.NACK 
		)
		&sql(OPEN cNack)
		for {
			&sql(FETCH cNack)
			quit:(SQLCODE'=0)
			set ntotal = ntotal + 1
			
			// check if originalId references non-existing message
			if '$data(^Ens.MessageHeaderD(originalId)) {
				&sql(DELETE FROM ITB_HL7_Data.NACK WHERE OriginalId=:originalId)
				if SQLCODE'=0 $$$ThrowStatus($$$ERROR($$$GeneralError, "Error while deleting ITB_HL7_Data.NACK id="_originalId)) 
				set ndeleted = ndeleted + %ROWCOUNT
			}
		}
		&sql(CLOSE cNack)
		do ..Log("Total="_ntotal_", Deleted="_ndeleted_$$$NL)
	} catch ex {
		set ret = ex.AsStatus()
		do ..Log("<ERROR> DeleteNACKTask: "_$system.Status.GetOneErrorText(ret))
	}
	quit ret
}

/// Log a text message
ClassMethod Log(pText As %String, ByRef pInfo)
{
	set tText = $zdt($h,3)_": "_pText
	write !,tText
	zwrite:$d(pInfo) pInfo
}

}
