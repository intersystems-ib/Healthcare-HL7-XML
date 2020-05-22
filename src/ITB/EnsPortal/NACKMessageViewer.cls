Include (Ensemble, EnsUI)

/// Viewer that displays information in ITB_HL7_Data.NACK table</br>
/// See <class>ITB.HL7.Data.NACK</class></br>
/// To install:</br>
/// <ul>
/// <li>If you want to add a menu link in Ensemble Portal Management, modify EnsPortal.Application:GetEnsembleArray</li>
/// </ul>
Class ITB.EnsPortal.NACKMessageViewer Extends EnsPortal.Template.standardPage
{

Parameter DOMAIN = "ITB";

/// User needs USE permissions on the %Ens_Dashboard resource to access this page.
Parameter RESOURCE = "%Ens_Dashboard:USE";

/// Displayed name of this page.
Parameter PAGENAME = "NACK Messages";

/// The text that is shown in TitlePane above the license
Property LocatorHeader As %ZEN.Datatype.caption [ InitialExpression = "ITB NACK Messages" ];

Property matchTarget As %ZEN.Datatype.string(ZENURL = "TARGET");

XData Style
{
<style type="text/css">
/*** Containers ***/
#wrapper {
	margin-top: 10px;
}
iframe {
	border-style:none;
	height:250px;
}

/*** Other ***/
.SectionTitle {
	background:#bababa;
}
.SectionTitle a {
	color: #404040 !important;
	font-size: 12pt;
}
.Text {
	font-size: 9pt;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" title="">
<group id="wrapper" width="100%">
<link caption="NACK Messages" target="new" href="EnsPortal.EventLog.zen" width="100%" enclosingClass="SectionTitle"/>
<hgroup width="100%" cellVAlign="top">
<!-- NACK Table -->
<group id="table-wrapper" width="60%">
<tablePane
id="nackTable"
useSnapshot="true"
maxRows="1000"
tableName="ITB_HL7_Data.NACK"
orderByClause="AckId DESC"
width="100%"
showRowSelector="false"
showZebra="true"
showFilters="true"
pageSize="28"
valueColumn="Messages"
onselectrow="zenPage.onSelectRowHandler(zenThis);"
>
<column colName="ID" hidden="true"/>
<column colExpression="AckId||','||OriginalId" colName="Messages" hidden="true"/>
<column width="7%"  colName="AckId" header="NACK" style="text-align:left;"/>
<column width="18%" colExpression="AckId->TimeProcessed" colName="ATime" header="Time"/>
<column width="5%"  colName="MSAAckCode" header="ACK"/>
<column width="20%" colName="MSHControlID" header="MSH ID"/>
<column width="7%"  colName="OriginalId" header="Message" onclick="zenPage.messageViewerHandler('#(%query.OriginalId)#');" link="#" style="text-align:left;"/>
<column width="18%" colExpression="OriginalId->TimeProcessed" colName="OTime" header="Time"/>
<column width="20%" colName="Target" header="Target" filterType="text" id="TargetColumn"/>
<column width="5%" link="javascript:zenPage.deleteEntryHandler('#(%query.ID)#');" linkCaption="Delete" linkConfirm="Are you sure?"
/>
</tablePane>
<tableNavigatorBar tablePaneId="nackTable" showPageSize="false" showFilter="false"/>
</group>
<!-- Details -->
<group id="detail-wrapper" width="40%">
<link caption="NACK" href="#" width="100%" enclosingClass="SectionTitle"/>
<iframe id="ackContent" width="100%" src=""/>
<link caption="Message" href="#" width="100%" enclosingClass="SectionTitle"/>
<iframe id="msgContent" width="100%" src=""/>
</group>

</hgroup>
</group>
</pane>
}

/// NACK Table: select row
ClientMethod onSelectRowHandler(evt) [ Language = javascript ]
{
	var id = zen("nackTable").getValue();
	var ids = id.split(",");
	
	if (ids.length==2 && ids[0]!="" && ids[1]!="") {
		var url = zenLink("EnsPortal.MessageContents.zen?HeaderClass=Ens.MessageHeader&HeaderId="+ids[0])
		zen("ackContent").setProperty("src",url);
	
		url = zenLink("EnsPortal.MessageContents.zen?HeaderClass=Ens.MessageHeader&HeaderId="+ids[1])
		zen("msgContent").setProperty("src",url);
	}
}

/// NACK Table: delete (manually) an entry handler
ClientMethod deleteEntryHandler(id) [ Language = javascript ]
{
	var ret = zenPage.DeleteEntry(id)
	zen("nackTable").executeQuery();
}

/// NACK Table: delete (manually) an entry
Method DeleteEntry(pId As %String) As %String [ ZenMethod ]
{
	set tSC = ##class(ITB.HL7.Data.NACK).%DeleteId(pId)
	quit tSC
}

/// Open message viewer for an specific message id
ClientMethod messageViewerHandler(id) [ Language = javascript ]
{
	var url = zenPage.GetMessageViewerURL(id);
	window.open(url);
}

/// Return a URL to MessageViewer to search for an specific message and sets session search criteria as well
Method GetMessageViewerURL(pId As %String) As %String [ ZenMethod ]
{
	// build URL
	set tUrl = "EnsPortal.MessageViewer.zen"
	
	// add session search criteria
	if $l(pId) set %session.Data("Ensemble","SearchCriteria",$namespace)=$lb($lb(3,2,"","999",0,"",pId,"","",pId,"","","","","",""),"EnsPortal.MsgFilter.Filter")
	
	quit tUrl
}

/// Executed after page is created (ZEN)
Method %OnAfterCreatePage() As %Status
{
	set ret=$$$OK
	try { 
		set %page.%GetComponentById("TargetColumn").filterValue = ..matchTarget
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

}
