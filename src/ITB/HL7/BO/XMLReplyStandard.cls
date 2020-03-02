/// HL7 XML operations common class that handles ReplyCodeActions </br>
/// Based on <class>EnsLib.HL7.Operation.ReplyStandard</class></br>
Class ITB.HL7.BO.XMLReplyStandard Extends (Ens.BusinessOperation, ITB.HL7.XMLHost)
{

/// A comma-separated list of codes specifying what action this Operation will take on receipt of various types of ACK response messages and other reply status conditions. <br/>
/// The format of the list is: &lt;code&gt;=&lt;action&gt;,&lt;code&gt;=&lt;action&gt;,... <br/>
/// A &lt;code&gt; value starting with a colon - e.g. :&lt;char&gt;&lt;char&gt; represents a literal value found in field MSA:1 of the response message. <br/>
/// Also, the following special code values may be used: <br/>
/// :?A - matches AA or CA values (Accept) <br/>
/// :?E - matches AE or CE values (Error) <br/>
/// :?R - matches AR or CR values (Reject) <br/>
/// :_  - matches replies with an empty MSA:1 field <br/>
/// :*  - matches any MSA:1 value not matched otherwise (default=F) <br/>
/// :~  - matches replies that do not contain an MSA segment <br/>
/// :I? - matches where the reply MSA:2 ControlId does not match the ControlId of the original message <br/>
/// :T? - matches where the reply MSH:9 Type name does not match the schema's declared reply type for the original message <br/>
///  <br/>
/// Also, the following standard status conditions may be used: <br/>
/// E - Error status returned from message handler <br/>
/// E#&lt;statuscode&gt; - Error status returned from message handler has status code equal to &lt;statuscode&gt; <br/>
/// E*&lt;text&gt; - Error status returned from message handler contains text string &lt;text&gt; <br/>
/// X - there is no reply message at all <br/>
/// Note: an empty or whitespace code value is the same as :_. <br/>
///  <br/>
/// The following values for &lt;action&gt; may be used alone or in combinations: <br/>
/// C - Treat the message as Completed OK. <br/>
/// W - Log a warning but treat the message as Completed OK. <br/>
/// R - Retry the message according to the configured RetryInterval and FailureTimeout; finally Fail unless a different action is also specified <br/>
/// S - Suspend the message, log an error, and move on to try the next message <br/>
/// D - Disable the Operation, log an error and restore the outbound message to the front of the Operation's queue <br/>
/// F - Fail with an error and move on to try the next message <br/>
/// Note: F is the default action if no other is given, except for code ?A where the default action is C <br/>
///  <br/>
/// The default behavior is ':?R=RF,:?E=S,:~=S,:?A=C,:*=S,:I?=W,:T?=C' <br/>
/// This means for NACKs received with error code AR or CR retry, while codes AE or CE suspend the current outbound
/// message and move on to the next.<br/>
///  <br/>
/// All codes where the &lt;actions&gt; consists of only 'W' (for 'log a Warning') will be evaluated and warnings generated if they trigger.
/// Other codes will be evaluated in left-to-right order, executing the first one that triggers that has a non-warning &lt;actions&gt; value.
Property ReplyCodeActions As %String(MAXLEN = 1000);

Parameter SETTINGS = "ReplyCodeActions,NoFailWhileDisconnected,SaveReplies";

/// Save a copy of reply messages sent back to the remote system. Also optionally index them using the configured SearchTableClass, if any.<br/>
/// The options for this setting are as follows: <ul>
/// <li>None : Don't save or index any reply messages.</li>
/// <li>NotOKs : Save replies that are not a simple OK ACK message: e.g. error NACKS and query responses.</li>
/// <li>All : Save a copy of all reply messages sent back to the remote system.</li>
/// <li>IndexNotOKs : Save replies that are not a simple OK ACK message and index them using the configured SearchTable.
/// This is the default behaviour, unless <parameter>IndexReplies</parameter>, <parameter>SaveOKACKs</parameter> or 
/// <parameter>IndexACKs</parameter> has been overridden in this class.</li>
/// <li>IndexAll : Save a copy of all reply messages and index them using the configured SearchTable.</li></ul>
Property SaveReplies As %String(VALUELIST = ",None,NotOKs,All,IndexNotOKs,IndexAll") [ InitialExpression = "IndexNotOKs" ];

/// parsed array property of ReplyCodeActions setting
Property %replyActionMap [ MultiDimensional ];

Method OnInit() As %Status
{
 	// The default behavior is ':?R=RF,:?E=S,:~=S,:?A=C,:*=S,:I?=W,:T?=C' <br/>
	Set:""=..ReplyCodeActions ..ReplyCodeActions=":?R=RF,:?E=S,:~=S,:?A=C,:*=S,:I?=W,:T?=C"
	Do ..buildReplyActionMap()
	Quit ##super()
}

/// build parsed array property of ReplyCodeActions setting
Method buildReplyActionMap() As %Status
{
	Set nActions=$S(""=$ZStrip(..ReplyCodeActions,"<>W"):0, 1:$L(..ReplyCodeActions,","))
	Set (tFirst,tOther)=0
	For i=1:1:nActions { Set tType=$P(..ReplyCodeActions,",",i)  Continue:""=tType
		Set tCode=$ZStrip($P(tType,"="),"<>W"), tCodeU=$ZCVT(tCode,"U")
		Set tAction=$ZCVT($ZStrip($P(tType,"=",2),"<>W"),"U")
		Continue:tCode_tAction=""
		If tOther { If tOther-tFirst>1 { Continue } Else { Set (tFirst,tOther)=0 Kill ..%replyActionMap /* loner; start again */ } }
		If ":"=$E(tCode)&&$Case(tCodeU,":I?":0,":T?":0,:1) { Set:'tFirst tFirst=i } Else { Set:("W"'=tAction)&&tFirst tOther=i  Continue }
		
		#; Now we are in a cluster of : values that we want to build a map from
		Set tCode=$E(tCode,2,*), tCodeU=$E(tCodeU,2,*)
		Continue:""=tCode&&$D(..%replyActionMap("_"))

		Set:""=tCode tCode="_"
		Set:"~"=tCode tCode="~NoMSA"
		Set:tAction'?1.(1"C",1"W",1"R",1"S",1"D",1"F") tAction=$Case(tCodeU
																	,"?A":"C"
																	,"AA":"C"
																	,"CA":"C"
																	,:"F")
		Set:tAction?1."R" tAction="RF"
		If tCodeU?1"?"1(1"A",1"E",1"R") {
			Set ..%replyActionMap("A"_$E(tCodeU,2))=tAction
			Set ..%replyActionMap("C"_$E(tCodeU,2))=tAction
		} ElseIf tCodeU?1(1"A",1"C")1(1"A",1"E",1"R") {
			Set ..%replyActionMap(tCodeU)=tAction
		} Else {
			Set ..%replyActionMap(tCode)=tAction
		}
	}
	#; optimization: use map if ':' conditions are grouped together
	Set tEnd=$S(tOther:tOther-1,1:nActions)
	Set:tFirst&&(tEnd-tFirst>0) ..%replyActionMap("%UseMapAt",tFirst)=tEnd
	Quit $$$OK
}

/// Construct and return an Action string consisting of supported action code letters, based on qualities of the Request, Response, and Error Status.
Method OnGetReplyAction(pRequest As EnsLib.HL7.Message, Output pResponse As EnsLib.HL7.Message, ByRef pSC As %Status) As %String
{
	Set (tCode,tAckCode,tFullAction,tText)=""
	Set nActions=$S(""=$ZStrip(..ReplyCodeActions,"<>W"):0, 1:$L(..ReplyCodeActions,","))
	Set tUseMapAt=$O(..%replyActionMap("%UseMapAt",""),1,tLastI)  Set:""=tUseMapAt tUseMapAt=nActions+1
	Set tReplyTypeName=$G(..%ActionHint("AckType"))
	For i=1:1:nActions { Set tType=$P(..ReplyCodeActions,",",i)  Continue:""=tType
		If ""'=tCode $$$LOGWARNING("Unrecognized reply code:'"_tCode_"'")
		Set tAction="", tCode=$ZStrip($P(tType,"="),"<>W"), tCodeU=$ZCVT(tCode,"U")
		Set tKnown=$Case($E(tCodeU)
						,"E":$Case($E(tCode,2)
								,"#":1
								,"*":1
								,"":1
								,:0)
						,"X":$Case($E(tCode,2),"":1,:0)
						,":":1
						,:0)
		Continue:'tKnown
		Set tMatch=$Case($E(tCodeU)
			,"":0
			,"E":$$$ISERR(pSC)
			,"X":'$$$IsdefObject(pResponse)
			,":":-1
			,:"")
		If tMatch>0 {
			Set tMatch=$Case($E(tCode,2)
							,"#":$$$StatusEquals(pSC,$E(tCode,3,*))
							,"*":$$$StatusText(pSC)[$E(tCode,3,*)
							,:1)
			If tMatch {
				If $E(tCodeU)="X" {
					Set tMatchText="Empty Response object matched ReplyCodeAction "_i_" : ':"_tCode_"'"
				} Else {
					Set tMatchText="Status '"_$$$StatusDisplayString(pSC)_"' matched ReplyCodeAction "_i_" : '"_tCode_"'"
				}
			}
		} ElseIf tMatch<0 {
			Set tMatch=0
			If '$$$IsdefObject(pResponse) Set tCode=""  Continue
			If ":I?"=tCode {
				Do:""=tAckCode getACKCode
				If ("~NoMSA"'=tAckCode)&&("1-byte "'=$E(tMSA.GetValueAt(3),1,$L("1-byte "))) {
					Set tReq=pRequest  While $Case(tReq.Name,"FHS":1,"BHS":1,:0) {
						Set tReq=tReq.NextChild()
						If '$IsObject(tReq) Set tReq=pRequest  Quit
					}
					Set tRequestControlID = tReq.GetValueAt("1:10")
					If (tRequestControlID'=tMSA.GetValueAt(2)) {
						Set tMatch=1, tMatchText="MSA:2 ControlId '"_tMSA.GetValueAt(2)_"' does not match original message ControlId '"_tRequestControlID_"'"
					}
				}
			} ElseIf ":T?"=tCode {
				Set tMatch=0, tReplyDocName=..%ActionHint("ReplyDocName")
				If ((tReplyTypeName '= tReplyDocName) && (tReplyDocName'="")) || (tReplyTypeName="") {
					Set tMatch=1, tMatchText="Reply message type "_tReplyTypeName_" does not match expected type "_tReplyDocName
				}
			} Else {
				#; Get MSA code if not already cached
				Do:""=tAckCode getACKCode
				#; Get action from the map, or test for a match the old fashioned way
				If i=tUseMapAt {
					#; Use map
					Set tAction=$G(..%replyActionMap(tAckCode))  If ""=tAction Set tAction=$G(..%replyActionMap(tAckCodeU))  If ""=tAction Set tAction=$G(..%replyActionMap("*"))
					Set tMatch=(""'=tAction)
					Set:tMatch tMatchText= "MSA code '"_tAckCode_"' matched ReplyCodeActions "_i_"-"_tLastI_" : '"_$P(..ReplyCodeActions,",",i,tLastI)_"'"
					Set i=tLastI ; skip other contiguous mapped ':' entries
				} Else {
					#; Don't use map; check it manually
					Set tCode=$E(tCode,2,*)
					If tCode?1"?"1(1"A",1"a",1"E",1"e",1"R",1"r") { Set tMatch=(tAckCodeU?1(1"A",1"C").E && ($E(tAckCodeU,2,*)=$ZCVT($E(tCode,2),"U"))) }
					ElseIf "_"=tCode { Set tMatch=("_"=tAckCode) }
					ElseIf "~"=tCode { Set tMatch=("~NoMSA"=tAckCode) }
					ElseIf "*"=tCode { Set tMatch=("~NoMSA"'=tAckCode) }
					ElseIf tCode?1(1"A",1"a",1"C",1"c")1(1"A",1"a",1"E",1"e",1"R",1"r") { Set tMatch=(tAckCodeU=$ZCVT(tCode,"U")) }
					Else {             Set tMatch=(tAckCode=tCode) }
					Set:tMatch tMatchText="MSA code '"_tAckCode_"' matched ReplyCodeAction "_i_" : ':"_tCode_"'"
				}
			}
		}
		If tMatch {
			Set:""=tAction tAction=$ZCVT($ZStrip($P(tType,"=",2),"<>W"),"U")
			If ""=tAction Set tCode=""  Continue
			Set:""'=tMatchText tText=tText_$S(""'=tText:" and ",1:"")_tMatchText
			#; Make sure tFullAction has no more than 1 'W' in it; Quit if it is not just 'W'
			Set:tAction["W" tFullAction=""
			Set tFullAction=tAction_$S(tAction["W":"",1:tFullAction)
			Quit:tFullAction'?1."W"
		} ElseIf tMatch'=0 {
			$$$LOGWARNING("Unrecognized reply code:'"_tCode_"'")
		} ; else it remains 0 and is not a match
		Set tCode=""
	}
	Set:""'=tText ..%ActionHint("CodeReason")=
		"HL7 Message body "_pRequest_" / "_pRequest.%Id()_" because response "_
		$S('$IsObject(pResponse):"'"_pResponse_"'", 1:pResponse_$S(""=pResponse.%Id():"",1:" / "_pResponse.%Id()))_" "_
		tText_", resulting in Action code "_tFullAction_
		$TR($S('$IsObject(pResponse):pResponse,1:" : "_pResponse.RawContent),$C(13)," ")

	#; Save reply if it's special, or if we're built to save even ordinary OK ACKs
	If $IsObject(pResponse) && ("None" '= ..SaveReplies) {
		Set tIsACK = ("ACK" = $P(tReplyTypeName,"_"))
		Set tDoAll = "All" = $extract(..SaveReplies,*-2,*)
		Do:(""=tAckCode)&&tIsACK&&'tDoAll getACKCode
		Set tIsOKACK = $Case(tAckCodeU, "AA":1, "CA":1, :0)
		#; Save the reply if we are saving/indexing all replies, OR this is not an OK ACK
		If tDoAll || 'tIsOKACK {
			#; Index reply if indexing is enabled
			If (""'=..SearchTableClass) && ("Index" = $extract(..SaveReplies,1,5)) {
				Set tSCStore=$classmethod(..SearchTableClass,"IndexDoc",pResponse)
				If $$$ISERR(tSCStore) $$$LOGWARNING("Failed to construct SearchTable instance for message "_pResponse_$S(""=pResponse.%Id():"",1:" / "_pResponse.%Id())_" with DocType='"_pResponse.DocType_"' using class '"_..SearchTableClass_"' "_$$$StatusDisplayString(tSCStore))
			}
			Else {
				Set tSCSave=pResponse.%Save()
				If $$$ISERR(tSCSave) $$$LOGERROR("Failed to save reply message "_pResponse_$S(""=pResponse.%Id():"",1:" / "_pResponse.%Id())_" with DocType='"_pResponse.DocType_"': "_$$$StatusDisplayString(tSCSave))
			}
		}
	}
	Quit tFullAction
getACKCode
	#; Get MSA code if not already cached
	Set tReplyDoc=pResponse
	While $Case(tReplyDoc.Name,"FHS":1,"BHS":1,:0) {
		Set tReplyDoc=tReplyDoc.NextChild()
		If '$IsObject(tReplyDoc) Set tReplyDoc=pResponse  Quit
	}
	Set tMSA=tReplyDoc.GetSegmentAt(2)
	Set tAckCode=$S($IsObject(tMSA)&&("MSA"=tMSA.GetValueAt(0)):$ZStrip(tMSA.GetValueAt(1),"<>W"), 1:"~NoMSA")
	Set:""=tAckCode tAckCode="_"
	Set tAckCodeU=$ZCVT(tAckCode,"U")
	Quit
}

}
