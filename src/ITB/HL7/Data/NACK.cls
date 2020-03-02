Include Ensemble

/// Utility class to handle async HL7 NACK application messages </br>
/// <ol>
/// <li>Operation: to send HL7 messages to an application that will send async NACKs</li>
///   <ul>
///     <li>Add an HL7 Operation (e.g. ITB.HL7.BO.TCPXMLOperation, ITB.HL7.BO.TCPOperation)</li>
///     <li>Activate <b>NACK Control</b> in Operation</li>
///     <li>Add an HL7 <b>SearchTable</b> in Operation</li>
///   </ul>
/// <li>Process: to handle incoming NACK messages</li>
///   <ul>
///     <li>Add an ITB.HL7.BP.NACKProcess</li>
///     <li>Set <b>Target</b> to the name of HL7 Operation that sent the original message</li>
///     <li>Add the same HL7 <b>SearchTable</b> that the Operation used so the process can find the original message</li>
///   </ul>
/// <li>Service: to receive incoming NACK messages</li>
///   <ul>
///     <li>Add an HL7 Service (e.g. ITB.HL7.BS.TCPXMLService, EnsLib.HL7.Service.TCPService)</li>
///     <li>Configure Service to send messages to ITB.HL7.BP.NACKProcess</li>
///   </ul>      
/// <li>Use <class>ITB.EnsPortal.NACKMessageViewer</class> ZEN page to view NACK messages</li>
/// </ol>
Class ITB.HL7.Data.NACK Extends %Persistent
{

/// Original HL7 message Id
Property OriginalId As Ens.MessageHeader;

/// Ack HL7 message Id
Property AckId As Ens.MessageHeader;

/// Original HL7 message MSHControlID field (MSH:10)
Property MSHControlID As %String;

/// Ack HL7 message AckCode (MSA:1)
Property MSAAckCode As %String;

/// Production item that sent the HL7 message
Property Target As %String(MAXLEN = 200);

Index MSHControlIdTargetIDX On (Target, MSHControlID);

Index AckIdIDX On AckId;

Index TargetIDX On Target As Upper [ Type = bitmap ];

/// Given a NACK HL7 message, mark referred message (MSA:MessageControlID) as error
/// pAckId: Message Header of the received NACK message.
/// pAckMsg: Message Body (HL7) of the received NACK message.
/// pTarget: Name of the production element (BO) that sent the original HL7 message.
/// pNackCodes: Comma separated list of NACK Codes that will be considered errors.
/// pSearchTable: Search table that will be used to search original message.
/// pAllowDuplicates: Allow more than one error entry (NACK) with the same MSHCControlID and Target.
/// 
/// pNumRows: Return the number of rows inserted.
/// pIdList: Return a list containing the IDs of the rows inserted.
ClassMethod InsertError(pAckId As Ens.MessageHeader, pAckMsg As EnsLib.HL7.Message, pTarget As %String, pNACKCodes As %String = "AE", pSearchTable As %String = "EnsLib.HL7.SearchTable", pAllowDuplicate As %Boolean = 0, Output pNumRows, Output pIdList) As %Status
{
	set ret = $$$OK
	try {
		set pNumRows = 0
		set pIdList = ##class(%ListOfDataTypes).%New()
		
		set tAckCode = pAckMsg.GetValueAt("MSA:1")
		
		if $l(tAckCode),$find(pNACKCodes,tAckCode) {
		  	set tMSHControlID = pAckMsg.GetValueAt("MSA:2")
		  	set tPropId = ..GetPropId(pSearchTable, "MSHControlID")
		  	if 'tPropId $$$ThrowStatus($$$ERROR($$$GeneralError,"Not MSHControlID field in "_pSearchTable_" SearchTable"))
		  	$$$THROWONERROR(tSC, $zobjclassmethod(pSearchTable,"Search",.tOutput, tPropId, tMSHControlID))
			
			if 'pAllowDuplicate {
				set tCount=0
				&sql(SELECT COUNT(*) INTO :tCount FROM ITB_HL7_Data.NACK WHERE MSHControlID=:tMSHControlID AND Target=:pTarget)
				set:SQLCODE'=0 tCount=0
				if tCount $$$ThrowStatus($$$ERROR($$$GeneralError,"Duplicate error entry not allowed. MSHControlID="_tMSHControlID_" Target="_pTarget))
			}
			
			set tRows = 0
			set tSession=""
			for {
				set tSession=$o(tOutput(tSession))
				quit:tSession=""
				set tHeader=""
				for {
					set tHeader=$o(tOutput(tSession,tHeader))
					quit:tHeader=""
					set tBody=""
					for {
						set tBody=$o(tOutput(tSession,tHeader,tBody))
						quit:tBody=""
						
						set tTarget=$lg(tOutput(tSession,tHeader,tBody),3)
						quit:tTarget'=pTarget
						
						set tObj = ##class(ITB.HL7.Data.NACK).%New()
						set tObj.OriginalId = ##class(Ens.MessageHeader).%OpenId(tHeader)
						set tObj.AckId = pAckId
						set tObj.MSHControlID = tMSHControlID
						set tObj.MSAAckCode = tAckCode
						set tObj.Target = tTarget
						$$$THROWONERROR(tSC, tObj.%Save())
						
						// add to list of IDs that has been inserted
						do pIdList.Insert(tObj.%Id())
						
						set tRows = tRows + 1
					}
				}	
			}
			set tMsg = "NACK Insert: MSHControlID="_tMSHControlID_" AckCode="_tAckCode_" InsertedRows="_tRows
			if tRows {$$$TRACE(tMsg)} else {$$$LOGWARNING(tMsg)}
			set pNumRows = tRows
	  	} 
	  	else {
		  	$$$LOGWARNING("NACK Insert: Ignoring AckCode="_tAckCode)
		}
	} catch ex {
		set ret = ex.AsStatus()
		$$$LOGERROR("NACK Insert: "_$system.Status.GetOneErrorText(ret))
	}
	quit ret
}

/// Given a HL7 message, remove error entries based on its MSH:MessageControlID
ClassMethod RemoveError(pMsg As EnsLib.HL7.Message, pTarget As %String) As %Status
{
	set ret = $$$OK
	try {
		set tMSHControlID = pMsg.GetValueAt("MSH:10")
		&sql(DELETE FROM ITB_HL7_Data.NACK WHERE MSHControlID=:tMSHControlID AND Target=:pTarget)
		$$$TRACE("NACK Remove: MSHControlID="_tMSHControlID_" Target="_pTarget_" DeletedRows="_%ROWCOUNT)
	} catch ex {
		set ret = ex.AsStatus()
		$$$LOGERROR("NACK Remove: "_$system.Status.GetOneErrorText(ret))
	}
	quit ret
}

/// Return the PropertyId of a given PropertyName in EnsLib.HL7.SearchTable
ClassMethod GetPropId(pSearchTable As %String, pPropName As %String) As %String [ Private ]
{
	set tPropId = $get($$$EnsJobLocal("SearchTableCache",pSearchTable,pPropName))
	if tPropId quit tPropId
	
	&sql(SELECT PropID INTO :tPropId FROM Ens_Config.SearchTableProp WHERE ClassExtent = :pSearchTable AND Name = :pPropName)
	if SQLCODE = 0 {
		if $data($$$EnsJobLocal) { Set $$$EnsJobLocal("SearchTableCache",pSearchTable,pPropName) = tPropId }
		quit tPropId
	}
	quit 0
}

Storage Default
{
<Data name="NACKDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>OriginalId</Value>
</Value>
<Value name="3">
<Value>AckId</Value>
</Value>
<Value name="4">
<Value>MSHControlID</Value>
</Value>
<Value name="5">
<Value>MSAAckCode</Value>
</Value>
<Value name="6">
<Value>Target</Value>
</Value>
</Data>
<DataLocation>^ITB.HL7.Data.NACKD</DataLocation>
<DefaultData>NACKDefaultData</DefaultData>
<ExtentSize>100000</ExtentSize>
<IdLocation>^ITB.HL7.Data.NACKD</IdLocation>
<IndexLocation>^ITB.HL7.Data.NACKI</IndexLocation>
<StreamLocation>^ITB.HL7.Data.NACKS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
