/// System task to purge persistent objects non-referenced by Ens.MessageHeader
Class ITB.Task.PurgeNoRef Extends %SYS.Task.Definition
{

Parameter TaskName = "ITB.Task.PurgeNoRef";

/// 1=Really delete persistent objects, 0=Search objects only.
Property DeleteObjects As %Boolean [ InitialExpression = "0" ];

/// 1=Print IDs of objects found to delete, 0=Do not print object IDs.
Property Verbose As %Boolean [ InitialExpression = "1" ];

/// Comma separated list of classes to purge objects.
Property ClassList As %String(MAXLEN = "") [ InitialExpression = "EnsLib.HL7.Message" ];

/// Max count of objects to process.
Property MaxCount As %Integer [ InitialExpression = "10000" ];

/// Max count of objects to delete.
Property MaxDelete As %Integer [ InitialExpression = "1000" ];

/// Restrict deletes only to messages prior to the first non purged message
Property RestrictedMode As %Boolean [ InitialExpression = "0" ];

/// The OnTask() method is called to execute the task
Method OnTask() As %Status
{
	set ret = $$$OK
	try {
		do ..Log("=====================================")
		do ..Log("*PurgeNoRef Begin")
		for i=1:1:$l(..ClassList,",") {
			set cls = $piece(..ClassList,",",i)
			$$$THROWONERROR(tSC, ..DeleteNoRef(..DeleteObjects, ..Verbose, cls, ..MaxCount, ..MaxDelete, ..RestrictedMode))
		}
		do ..Log("*PurgeNoRef End")
	} catch ex {
		set ret = ex.AsStatus()
		do ..Log("<ERROR> OnTask: "_$system.Status.GetOneErrorText(ret))
	}
	quit ret
}

/// Delete persistent objects non-referenced by Ens.MessageHeader (persistent objecs that cannot be reached by Ensemble Purge Task)
/// <ul>
///  <li>pDeleteMessages: 1=delete objects, 0=search objects only.</li>
///  <li>pVerbose: 1=print ID of found objects.</li>
///  <li>pClass: persistent class in which search for non-referenced Ens.MessageHeader objects to delete.</li>
///  <li>pMaxCount: if greater than 0 max count of objects to process.</li>
///  <li>pMaxDeleted: if greater than 0 max count of non-referenced objects to process.</li>
///  <li>pProgress: if greater than 0 a "." will be printed for every pProgress number of objects processed.</li>
///  <li>pRestricted: if greater than 0, it will not delete messages which ID are greater than the first ID found in MessageHeader
/// </ul>
/// <example>
/// ; print objects only
/// do ##class(ITB.Task.PurgeNoRef).DeleteNoRef(0,1,"EnsLib.HL7.Message")
/// ; delete objects
/// do ##class(ITB.Task.PurgeNoRef).DeleteNoRef(1,0,"EnsLib.HL7.Message")
/// </example>
ClassMethod DeleteNoRef(pDeleteMessages As %Boolean = 0, pVerbose As %Boolean = 0, pClass As %String = "EnsLib.HL7.Message", pMaxCount As %Integer = 10000, pMaxDelete As %Integer = 1000, pProgress As %Integer = 0, pRestricted As %Integer = 0) As %Status
{
	set ret = $$$OK
	try {
		set (ncount,ntotal,ndeleted,nerrors)=0
		set minimumID = ..GetMinimumID(pClass)
		set tTxt=
		$$$NL_"**DeleteNoRef (process="_$job_")**"_
		$$$NL_"Parameters: "_
		$$$NL_"  pClass="_pClass_
		$$$NL_"  pDeleteMessages="_pDeleteMessages_
		$$$NL_"  pVerbose="_pVerbose_
		$$$NL_"  pMaxCount="_pMaxCount_
		$$$NL_"  pMaxDelete="_pMaxDelete_
		$$$NL_"  pProgress="_pProgress_
		$$$NL_"  pRestricted="_pRestricted_" (only ids smaller to "_minimumID_")"_
		$$$NL_"Looking for objects non referenced by Ens.MessageHeader..."_$$$NL
		do ..Log(tTxt)
		
		set rset = ##class(%ResultSet).%New(pClass_":Extent")
 		$$$THROWONERROR(tSC, rset.Execute())
 		
 		// Loop over pClass objects
 		while (rset.Next()) {
     		set id = rset.Data("ID")
 		
		    if (pRestricted) && (id >= minimumID){
	     		do ..Log($$$NL_"WARNING: Restricted mode. Reached first message not purged!"_$$$NL)
	     		quit
     		}

			// Look for obj id in MessageHeader/MessageBodyId index
			set headerId="", ref=0, delete=0
			for {
				set headerId=$order(^Ens.MessageHeaderI("MessageBodyId",id,headerId))
				quit:headerId=""
				
				// if there is a reference to id and it is a pClass object, increment reference count
				set msgBodyClassName=""
				
				&sql(SELECT MessageBodyClassName into :msgBodyClassName FROM Ens.MessageHeader WHERE id=:headerId)
				set:SQLCODE'=0 msgBodyClassName=""
				
				if msgBodyClassName=pClass {
					set ref=ref+1
				}
			}
			
			// if no references to id, set delete flag
			if ref=0 {
				set delete=1
			}
			
			// if delete flag, delete the non-referenced object
			if delete {
				if pVerbose write !,id
				
				set ntotal=ntotal+1
				if pDeleteMessages=1 {
					set sc=$classmethod(pClass,"%DeleteId",id)
					if $$$ISOK(sc) {
						set ndeleted=ndeleted+1
					} else {
						set nerrors=nerrors+1
					}
				}
			}
			
			set ncount=ncount+1
			if (pVerbose=0),(pProgress>0),(ncount#pProgress=0) write "."
			
			
			// check if max count/delete reached
			if (pMaxCount>0),(pMaxCount<=ncount) {
				do ..Log($$$NL_"WARNING: MaxCount reached!"_$$$NL)
				quit
			}
			if (pMaxDelete>0),(pMaxDelete<=ntotal) {
				do ..Log($$$NL_"WARNING: MaxDelete reached!"_$$$NL)
				quit
			}
		}
		
		do ..Log($$$NL_"Total: "_ntotal_", Deleted: "_ndeleted_", Errors: "_nerrors_$$$NL)
	} catch ex {
		set ret = ex.AsStatus()
		do ..Log("<ERROR> DeleteNoRef: "_$system.Status.GetOneErrorText(ret))
	}
	quit ret
}

/// Obtains the minimum MessageBodyID for a specified class name
ClassMethod GetMinimumID(pClassName As %String) As %Integer
{
	Set tMsgId=0
	&SQL(SELECT MIN(MessageBodyId), TimeCreated INTO :tMsgId, :tTimeCreated
	     FROM Ens.MessageHeader
	     WHERE MessageBodyClassName =:pClassName)
	Quit tMsgId
}

/// Log a text message
ClassMethod Log(pText As %String, ByRef pInfo)
{
	set tText = $zdt($h,3)_": "_pText
	write !,tText
	zwrite:$d(pInfo) pInfo
}

}
