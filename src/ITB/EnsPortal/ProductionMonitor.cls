Include (Ensemble, EnsUI)

/// Ensemble production monitor that displays information based on categories.</br>
/// See <class>EnsPortal.ProductionMonitor</class></br>
/// To install:</br>
/// <ul>
/// <li>do ##class(ITB.EnsPortal.ProductionMonitor).Translation()</li>
/// <li>If you want to add a menu link in Ensemble Portal Management, modify EnsPortal.Application:GetEnsembleArray</li>
/// </ul>
Class ITB.EnsPortal.ProductionMonitor Extends EnsPortal.Template.standardPage
{

Parameter DOMAIN = "ITB";

/// User needs USE permissions on the %Ens_Dashboard resource to access this page.
Parameter RESOURCE = "%Ens_Dashboard:USE";

/// Displayed name of this page.
Parameter PAGENAME = "Production Monitor";

/// Category name for non-categorized business hosts
Parameter NOCATEGORY = "_NoCategory_";

/// The text that is shown in TitlePane above the license
Property LocatorHeader As %ZEN.Datatype.caption [ InitialExpression = "ITB Production Monitor" ];

/// Time of last update
Property lastUpdate As %ZEN.Datatype.string [ InitialExpression = {$$$timeLocal} ];

/// Number of categories
Property NumCategory As %ZEN.Datatype.integer;

/// Categories (comma separated list)
Property Categories As %String(MAXLEN = "");

/// Categories marked as error (comma separated list)
Property ErrorCategories As %String(MAXLEN = "");

/// Total queued messages
Property TotalQueuedMessages As %Integer [ InitialExpression = 0 ];

XData Style
{
<style type="text/css">
/*** Monitor Data ***/
.MonitorTable {
	font-size: 0.8em;
}

.MonitorTable td {
	border: 1px solid gray;
}

.MonitorTable td.Item {
}

.MonitorTable td.Item:hover {
	background: yellow;
}

.MonitorHeaderLabel {
	font-weight: bold;
	font-size: 12pt;
	color: #404040;
	border: 1px solid gray;
}

.Lamp {
	text-align: center;
	color: darkblue;
	width: 30px;
	min-width: 20px;
	font-weight: bold;
}

.LampError {
	color: red;
}

.LampAlert {
	color: orange;
}

.LampNACK {
	color: #D57100;
}

.Error {
	background: red;
}

.Column {
	padding-left: 30px;
	padding-right: 30px;
}

.Clickable {
	cursor: pointer;
}

.Event {
	text-align:center;
	font-weight:bold;
}

.EventAlert {
	background:yellow;
}

.EventError {
	background:red;
	color:white;
}

.EventWarning {
	background:orange;
}

/*** Expandable Categories ***/
.expandoNode {
	margin-top:0px;
	padding-bottom:0px;
}

.expandoNode a {
	font-weight:bold !important;
	color:black;
}

/*** Containers ***/
#main {
	overflow-y:auto;
	height:400px;
}

#wrapper {
}

#bottom {
	margin-top : 30px;
}

#eventlog-wrapper {
	margin: 0px 10px 0px 10px;
}

#summary-wrapper {
	margin: 0px 10px 0px 10px;
}

#summary-content .link {
	font-size: 12px;
}
#loadinglayer {
	background-color: #ffffff;
	font-size: 30px;
	width: 100%;
  	height: 100%;
  	top: 0px;
  	left: 0px;
  	position: fixed;
  	display: block;
  	opacity: 0.7;
  	z-index: 99;
  	text-align: center;
}

/*** Other ***/
.SectionTitle {
	background:#bababa;
}
.SectionTitle a {
	color: #404040 !important;
	font-size: 12pt;
}
</style>
}

XData contentPane [ XMLNamespace = "http://www.intersystems.com/zen" ]
{
<pane xmlns="http://www.intersystems.com/zen" title="">
<timer id="timer" ontimeout="zenPage.timerHandler();" timeout="60000"/>
<group id="wrapper" width="100%">
<!-- Toolbox -->
<hgroup width="100%" labelPosition="left" cellAlign="left">
<text id="lastUpdate" label="Last update:" disabled="true"/>
<spacer width="20px"/>
<checkbox id="autoUpdate" label="Auto update:" value="0"/>
<image title="Update" src="deepsee/loop_24.gif" onclick="zenPage.updateContentHandler('');"/>
<spacer width="20px"/>
<label label="@Show:@Show:"/>
<link caption="All" href="#" onclick="zenPage.updateContentHandler('ALL');"/>
<link caption="@Nothing@Nothing" href="#" onclick="zenPage.updateContentHandler('NOTHING');"/>
<link caption="Errors" href="#" onclick="zenPage.updateContentHandler('ERROR');"/>
<spacer width="20px"/>
<link id="productionLink" label="" caption="" target="new"/>
</hgroup>
<!-- Main (Monitor Data)-->
<group id="main" width="100%">
<hgroup width="100%" containerStyle="background:#bababa;padding-left:20px;">
<label id="ServiceTitle" value="Service" width="33%" enclosingClass="MonitorHeaderLabel Column"/>
<label id="ProcessTitle" value="Process" width="33%" enclosingClass="MonitorHeaderLabel Column"/>
<label id="OperationTitle" value="Operation" width="33%" enclosingClass="MonitorHeaderLabel Column"/>
</hgroup>
<group id="monitor-content" width="100%"/>
</group>
<!-- Bottom-->
<hgroup id="bottom" width="100%" cellVAlign="top">
<!-- Event log -->
<group id="eventlog-wrapper" width="85%">
<link caption="Event Log" target="new" href="EnsPortal.EventLog.zen" width="100%" enclosingClass="SectionTitle"/>
<tablePane
id="eventLogTable"
useSnapshot="false"
maxRows="10"
tableName="Ens_Util.Log"
whereClause="(Type='Error' OR Type='Warning' OR Type='Alert')"
orderByClause="Id DESC"
width="100%"
showRowSelector="false"
showZebra="true"
>
<column width="5%" colName="Type" OnDrawCell="DrawType" header="Type"/>
<column width="15%" colName="ConfigName" header="Source"/>
<column width="65%" colName="Text" header="Text"/>
<column width="5%" colName="TimeLogged" OnDrawCell="DrawTimeLogged" header="Time"/>
</tablePane>
</group>
<!-- Summary -->
<group id="summary-wrapper" width="15%">
<link caption="Info" href="#" width="100%" enclosingClass="SectionTitle"/>
<group id="summary-content" width="100%"/>
</group>
</hgroup>
</group>
<group id="loadinglayer" enclosingClass="loadinglayer" hidden="true" width="100%" height="100%" layout="vertical">
<spacer height="45%"/>
<image src="/csp/broker/images/busy.gif"/>
</group>
</pane>
}

/// Handles timer to autoupdate content
ClientMethod timerHandler() [ Language = javascript ]
{
	if (zen("autoUpdate").value) {
		zenPage.updateContentHandler('');
	}
}

/// <p>Update page content</p>
/// <parameter>option</parameter>: expand categories option {"","ALL","ERROR","NOTHING"}
ClientMethod updateContentHandler(option) [ Language = javascript ]
{
	var ret = zenPage.showLoadingLayer(); 
	setTimeout(function(){zenPage.updateContentDeferred(option);},100);
}

/// Delegated deferred method to allow loading layer to show up and close
ClientMethod updateContentDeferred(option) [ Language = javascript ]
{
	zenSynchronousMode = true;
	var ret = zenPage.UpdateContent();
	zen("eventLogTable").executeQuery();
	
	// calculate which categories should be expanded
	if (option != "") this.expandedCategory = {};
	
	// this.Categories has all categories names
	// this.ErrorCategories has all errored categories	
	if (option=="ALL") {
		zenPage.calculateExpanded(this.Categories, true);
	}
	else if (option=="NOTHING") {
		zenPage.calculateExpanded(this.Categories, false);
	}
	else if (option=="ERROR") {
		zenPage.calculateExpanded(this.ErrorCategories, true);
	}
	
	try {
		for (var key in this.expandedCategory) {
			if (key && key!=undefined && key!='undefined') {
				zen(key).setExpanded(this.expandedCategory[key]);
			}
		}
	} catch(err) {
		;
	}
	zen("timer").startTimer();
	zenSynchronousMode = false;
	
	return 0;
}

/// Show "loading" layer
ClientMethod showLoadingLayer() As %String [ Language = javascript ]
{
   	zen("loadinglayer").setHidden(false);
	return 0;
}

/// Close "loading" layer
ClientMethod closeLoadingLayer() As %String [ Language = javascript ]
{
	zen("loadinglayer").setHidden(true);
	return 0;
}

/// Utility method to calculate expanded categories
ClientMethod calculateExpanded(arr, value) [ Language = javascript ]
{
	var categories = arr.split(",");
	for (var i=0; i<arr.length; i++) {
		var cat = categories[i];
		if (cat && cat!=undefined && cat!='undefined') {
			this.expandedCategory[cat] = value;
		}
	}
}

/// Handles a click on a expandable category. Stores expanded option.
ClientMethod expandoClickHandler(obj) [ Language = javascript ]
{
	this.expandedCategory[obj.id] = obj.expanded;
}

/// Open a link (event log, messages, queue) when clicking on a host name
ClientMethod openLink(type, id) [ Language = javascript ]
{
	var url="";
	
	if (type=="EventLog") {
		url = "EnsPortal.EventLog.zen?SOURCE="+id;
	}
	else if (type=="Message") {
		url = "EnsPortal.MessageViewer.zen?SOURCEORTARGET="+id;
	}
	else if (type=="Queue") {
		url = "EnsPortal.QList.cls?QUEUE="+id;
	}
	else if (type=="NACK") {
		url = "ITB.EnsPortal.NACKMessageViewer.cls?TARGET="+id;
	}
	
	if (url!="") {
		window.open(url);
	}
}

/// Converts a horolog datetime to minutes
ClassMethod ToMinutes(pHorolog As %String) As %String [ Private ]
{
	quit (+pHorolog*24*60)+(($piece(pHorolog,",",2))\60)
}

/// Returns Production StartTime in local time
Method GetStartTime() As %String [ ZenMethod ]
{
	set tTime = $get($$$EnsRuntime("StartTime"))
	if tTime="" quit ""
	
	set tUTC = $zdatetimeh(tTime,3)
	set tLocal = $zdatetimeh(tUTC,-3)
	quit $zdatetime(tLocal,3)
}

/// Returns running production name
Method GetProductionName() As %String [ ZenMethod ]
{
	quit $get($$$EnsRuntime("Name"))
}

/// Event Log Table. Draw TimeLogged column
Method DrawTimeLogged(pTable As %ZEN.Component.tablePane, pName As %ZEN.Datatype.string, pSeed As %ZEN.Datatype.string) As %Status
{
 	
	set tMinutes = ..ToMinutes($horolog)
	set tTimeLoggedMinutes = ..ToMinutes($zdth(%query(pName),3))
	set tAge = tMinutes - tTimeLoggedMinutes
	set tMsg = $select(
					tAge<120:$$$FormatText($$$Text("%1 min"),tAge), 
					tAge>(24*14*60):$$$FormatText($$$Text("%1 wk"),tAge\(24*60*7)),
					1:$$$FormatText($$$Text("%1 hr"),tAge\60)
				)
 	write tMsg
 	quit $$$OK
}

/// Event Log Table: Draw Type column.
Method DrawType(pTable As %ZEN.Component.tablePane, pName As %ZEN.Datatype.string, pSeed As %ZEN.Datatype.string) As %Status
{
	&html<
	<div width="100%" class="Event Event#(%query(pName))#"><span>#(%query(pName))#</span></div>
	>
 	quit $$$OK
}

/// Retrieve Production Info</br>
/// Get production monitor data and stores information in process private global ^||data</br>
Method GetHostInfo() As %Status
{
	set ret = $$$OK
	
	try {
		// ^||log: Ens_Util.Log information. Item name based global.
		kill ^||log
		set tStartTime = $G($$$EnsRuntime("StartTime"))
		set tSql = "SELECT ConfigName,Type,Count(*) As Total FROM Ens_Util.Log WHERE (Type=? OR Type=?) AND TimeLogged>=? GROUP BY Type,ConfigName"
    	set tStatement = ##class(%SQL.Statement).%New()
    	set tSC = tStatement.%Prepare(tSql)
    	set tRS = tStatement.%Execute($$$eLogTypeError,$$$eLogTypeAlert,tStartTime)
		while tRS.%Next() {  
			set tConfigName = tRS.%Get("ConfigName")
			continue:tConfigName=""
			
			set tType = tRS.%Get("Type")
			set tLogType=$case(tType,$$$eLogTypeError:"ErrorCount",$$$eLogTypeAlert:"AlertCount",:"")
			continue:tLogType=""
			
			set ^||log(tConfigName,tLogType)=+tRS.%Get("Total")
		}
		
		// ^||host: EnumerateHostStatus statistics. Item id based global.
		kill ^||host
		#dim tRS As %ResultSet
		set tRS = ##class(%ResultSet).%New()
		set tRS.ClassName = "Ens.Util.Statistics"
		set tRS.QueryName = "EnumerateHostStatus"
		set tSC = tRS.Execute()  quit:$$$ISERR(tSC)
		while (tRS.Next(.tSC)) {  
			quit:$$$ISERR(tSC)
			
			/*
			Name: is the name of the host item.
			Type: is the type (Service, Operation, etc.) of the host item.
			Status: is last reported status for the item.
			AdapterState: is connected status of jobs for this host.
			LastActivity: is local time of last activity on this host.
			ElapsedTime: is number of seconds from time of last activity on this host to now.
			Queue: is the current number of items in the queue associated with this item.
			Count: is the number of activities processed since it was started.
			*/
			
			// skip internal services
			set tName = tRS.Data("Name")
			continue:(tName="EnsLib.Testing.Service")||(tName="Ens.ManagerService")||(tName="Ens.ScheduleService")
			
			set tId = $g($$$ConfigId(tName))
			continue:tId=""
			
			set tItem = ##class(Ens.Config.Item).%OpenId(tId)
			continue:'$isobject(tItem)
			
			set tType = tRS.Data("Type")
			continue:tType=""
			
			set tProduction = ..GetProductionName()
			set tCategory = tItem.Category
			set:tCategory="" tCategory=..#NOCATEGORY
			
			set ^||host(tId,"Name") = tName
			set ^||host(tId,"Type") = tType
			set ^||host(tId,"Category") = tCategory
						
			#; host status
			set tStatus = $zcvt(tRS.Data("Status"),"U")
			set ^||host(tId,"Lamp") = $case(tStatus,"OK":"#80FF80", "ERROR":"#FF4040", "INACTIVE":"#FFFF80", :"#808080")
			set ^||host(tId,"Icon") = $case(tStatus,"ERROR":"!", "INACTIVE":"-", "DISABLED":"X", :"")
			set ^||host(tId,"Msg")  = $case(tStatus,"OK":$$$Text("OK"), "ERROR":$$$Text("Error"), "INACTIVE":$$$Text("Inactive"), "":"", :tStatus)
			set tIsOK = (tStatus="OK")
			
			#; adapter/connection state
			set tConnState = tRS.Data("AdapterState")
			set ^||host(tId,"CLamp") = $S(tConnState[" connected":"#80FF80", tConnState[" disconnected":"#FF4040", tConnState[" listening":"#FFFF80", 1:"#808080")
			set ^||host(tId,"CIcon") = $S(tConnState[" connected":"+", tConnState[" disconnected":"x", tConnState[" listening":"o", 1:"-")
			
			#; compose localized connection state text
			set (nConn,nDis,nListen)=0
			set tCMsg=$case(tConnState,"disabled":$$$Text("disabled"), "n/a":$$$Text("n/a"),"unscheduled":$$$Text("unscheduled"),"not connecting":$$$Text("no jobs"),:"")
				
			set tState=""
			if tCMsg="" {
				set tState(1)=$P(tConnState,",",1)
				set tState(2)=$P(tConnState,",",2)
				set tState(3)=$P(tConnState,",",3)
					
				for j=1:1:3 {
					set:tState(j)[" connected" nConn = +tState(j)
					set:tState(j)[" disconnected" nDis=+tState(j)
					set:tState(j)[" listening" nListen=+tState(j)
				}
					
				set tCMsg=""
				set:nConn||('nDis&&'nListen) tCMsg=$Case(nConn, 1:$$$Text("1 job connected"), :$$$FormatText($$$Text("%1 jobs connected"),nConn))
				set tCMsg = tCMsg_$Case(nDis, 0:"", 1:$S(""=tCMsg:"",1:", ")_$$$Text("1 job disconnected"), :$$$FormatText($$$Text("%1 jobs disconnected"),nDis))
				set tCMsg = tCMsg_$Case(nListen, 0:"", 1:$S(""=tCMsg:"",1:", ")_$$$Text("1 job listening"), :$$$FormatText($$$Text("%1 jobs listening"),nListen))
			}
			set ^||host(tId,"CMsg")=tCMsg
			
			;# queue
			set tQueue=+tRS.Data("Queue")
			set tQIcon = tQueue
			set tQLamp = ..GetQueueColor(tQueue)
			set tQMsg = $s(tQueue<1:$$$Text("Queue is Empty"), tQueue<10:$$$Text("Under 10"), tQueue<50:$$$Text("Under 50"), tQueue<200:$$$Text("Under 200"),1:$$$Text("Over 200"))
			set ..TotalQueuedMessages = ..TotalQueuedMessages + tQueue
			set tIsOK = (tIsOK && (tQueue<1))
				
			set ^||host(tId,"QIcon")=tQIcon
			set ^||host(tId,"QLamp")=tQLamp
			set ^||host(tId,"QMsg")=tQMsg
				
			;# count
			set ^||host(tId,"Count")=+tRS.Data("Count")
			
			;# errors,alerts
			set ^||host(tId,"ErrorCount")=0
			set ^||host(tId,"AlertCount")=0
			
			;# grab data from ^||log if any
			if $data(^||log($zcvt(tName,"U"))) merge ^||host(tId)=^||log($zcvt(tName,"U"))
			
			;# NACK table data
			if tType="BusinessOperation" {
				set tNACKCount=0
				&sql(select count(*) into :tNACKCount from itb_hl7_data.nack where Target=:tName)
				set ^||host(tId,"NACKCount")=+tNACKCount
			}
			
			set ^||host(tId,"IsOK")=tIsOK
		}
		
		// ^||data: Category/Type based global. Front-end will display this information.
		kill ^||data
		set tId=""
		for {
			set tId=$o(^||host(tId))
			quit:tId=""
			
			set tCategory = ^||host(tId,"Category")
			set tType = ^||host(tId,"Type")
			for i=1:1:$l(tCategory,",") {
				set tCat = $p(tCategory,",",i)
				// grab data from ^||host
				merge ^||data(tCat,tType,tId) = ^||host(tId)
				// category is OK?
				set ^||data(tCat,"IsOK") = $g(^||data(tCat,"IsOK"),1) && (^||host(tId,"IsOK"))
			}
		}
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// Returns queue color for given queue count
Method GetQueueColor(tCount) As %String
{
	quit $s(tCount<1:"#00FF00", tCount<10:"#40A000", tCount<50:"#808000", tCount<200:"orange",1:"#FF4040")
}

/// Draw a category (expandable) and all its hosts (services, processes, operations)</br>
/// <parameter>pCategory</parameter> category to draw</br>
/// <parameter>pGroup</parameter> ZEN group where category will be drawn</br>
Method DrawCategory(pCategory As %String, ByRef pGroup) As %Status
{
	set ret = $$$OK
	try {
		set ..NumCategory = ..NumCategory + 1
		set isEven = ..NumCategory # 2
		
		set pGroup = ##class(%ZEN.Component.group).%New()
		set pGroup.width="100%"
		
		set wrapper = ##class(%ZEN.Component.group).%New()
		set wrapper.layout="horizontal"
		set wrapper.width="100%"
		
		set banner = ##class(%ZEN.Component.group).%New()
		set banner.width="1%"
		set banner.valign="top"
		
		set expando = ##class(%ZEN.Component.expando).%New()
		set expando.id = $zcvt(pCategory,"O","HTML")
		set expando.caption = pCategory
		set expando.width = "99%"
		set expando.childIndent="0px"
		set expando.expanded=0
		set expando.onclick="zenPage.expandoClickHandler(zenThis);"
		set categoryIsOK = $g(^||data(pCategory,"IsOK"))
		if 'categoryIsOK {
			set ..ErrorCategories = pCategory_","_..ErrorCategories
			set banner.enclosingClass=banner.enclosingClass_" Error"
		}
		
		set inner = ##class(%ZEN.Component.group).%New()
		set inner.layout = "horizontal"
		set inner.width="100%"
		
		set style=$s('isEven:"background:#ececec;",1:"background:#f7f7f7;")
		set inner.containerStyle = style
		set expando.containerStyle = inner.containerStyle
		
		$$$THROWONERROR(tSC,..DrawBusinessHostGroup(pCategory,"BusinessService",.serviceGroup))
		$$$THROWONERROR(tSC,..DrawBusinessHostGroup(pCategory,"BusinessProcess",.processGroup))
		$$$THROWONERROR(tSC,..DrawBusinessHostGroup(pCategory,"BusinessOperation",.operationGroup))
		
		do inner.%AddChild(serviceGroup)
		do inner.%AddChild(processGroup)
		do inner.%AddChild(operationGroup)
		
		do expando.%AddChild(inner)
		
		do wrapper.%AddChild(banner)
		do wrapper.%AddChild(expando)
		
		do pGroup.%AddChild(wrapper)
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// Draw a business host group (Services, Processes, Operations)
/// <parameter>pCategory</parameter> current category to draw </br>
/// <parameter>pType</parameter> BusinessService,BusinessProcess, BusinessOperation </br>
/// <parameter>pGroup</parameter> ZEN group where business host group will be drawn</br>
Method DrawBusinessHostGroup(pCategory As %String, pType As %String, ByRef pGroup) As %Status
{
	set ret = $$$OK
	try {
		set pGroup = ##class(%ZEN.Component.group).%New()
		set pGroup.valign = "top"
		set pGroup.width = "33%"
		set pGroup.enclosingClass = "Column"
		$$$THROWONERROR(tSC,..DrawBusinessHosts(pCategory,pType,.group))
		do pGroup.%AddChild(group)
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// Draw Business Hosts of a category and belonging to a given type </br>
/// Get the data from process private global ^||data and draw the info </br>
/// <parameter>pCategory</parameter> current category which host belongs to </br>
/// <parameter>pType</parameter> BusinessService,BusinessProcess, BusinessOperation </br>
/// <parameter>pGroup</parameter> ZEN group where business host will be drawn</br>
Method DrawBusinessHosts(pCategory As %String, pType As %String, ByRef pGroup) As %Status
{
	#define ESCJSHTML(%s)  $Replace($Replace($ZCVT(%s,"O","JS"),"<","\x3C"),">","\x3E")
	set ret = $$$OK
	try {
		set id="",html=""
		for {
			set id=$o(^||data(pCategory,pType,id))
			quit:id=""
			
			// data
			set tName=$g(^||data(pCategory,pType,id,"Name"))
			// data: status
			set tMsg=$g(^||data(pCategory,pType,id,"Msg"))
			set tLamp=$g(^||data(pCategory,pType,id,"Lamp"))
			set tIcon=$g(^||data(pCategory,pType,id,"Icon"))
			// data: adapter (connection)
			set tCLamp=$g(^||data(pCategory,pType,id,"CLamp"))
			set tCIcon=$g(^||data(pCategory,pType,id,"CIcon"))
			set tCMsg=$g(^||data(pCategory,pType,id,"CMsg"))
			// data: queue
			set tQLamp=$g(^||data(pCategory,pType,id,"QLamp"))
			set tQIcon=$g(^||data(pCategory,pType,id,"QIcon"))
			set tQMsg=$g(^||data(pCategory,pType,id,"QMsg"))
			// data: NACK
			set tNACKCount=$g(^||data(pCategory,pType,id,"NACKCount"))
			// data: count (messages)
			set tCount=$g(^||data(pCategory,pType,id,"Count"))
			set tErrorCount=$g(^||data(pCategory,pType,id,"ErrorCount"))
			set tAlertCount=$g(^||data(pCategory,pType,id,"AlertCount"))
			
			// format data
			set tLampStyle="background:"_$s(tLamp'="":tLamp, 1:"#C0C0C0")_";" 
			set tCLampStyle = "background:"_$s(tCLamp'="":tCLamp, 1:"#C0C0C0")_";"
			set tQLampStyle = "background:"_$s(tQLamp'="":tQLamp, 1:"#C0C0C0")_";"
			set tIcon=$s(tIcon'="":tIcon,1:"&#149;")
			
			// build html table to display host info
			set row=""
			
			// status
			set row=row_"<td class=""Lamp"" title="""_$$$Text("Status")_": "_$zcvt(tMsg,"O","HTML")_""" style="""_tLampStyle_""">&nbsp;"_tIcon_"&nbsp;</td>"
			
			// adapter status
			if (pType="BusinessService")||(pType="BusinessOperation") {
				set row=row_"<td class=""Lamp"" title="""_$$$Text("Adapter")_": "_$zcvt(tCMsg,"O","HTML")_""" style="""_tCLampStyle_""">&nbsp;"_tCIcon_"&nbsp;</td>"
			}
			
			set jsID=$$$ESCJSHTML(tName)
			
			// queue
			set row=row_"<td class=""Lamp Clickable"" title="""_$$$Text("Queue")_": "_$zcvt(tQMsg,"O","HTML")_""" style="""_tQLampStyle_""" onclick=""zenPage.openLink('Queue','"_jsID_"');"">&nbsp;"_tQIcon_"&nbsp;</td>"
			
			// NACK count
			if pType="BusinessOperation" {
				set row=row_"<td class=""Lamp LampNACK Clickable"" title="""_$$$Text("@Number of NACKs@Number of NACKs")_""" onclick=""zenPage.openLink('NACK','"_jsID_"');"">&nbsp;"_tNACKCount_"&nbsp;</td>"
			}
			
			// name + detail link
			set row=row_"<td class=""Item"" width=""100%"" nowrap title="""_$zcvt(tName,"O","HTML")_""">&nbsp;"_$zcvt(tName,"O","HTML")_"&nbsp;</td>"
			
			// count (messages)
			set row=row_"<td class=""Lamp Clickable"" title="""_$$$Text("Number of messages processed since production start")_""" onclick=""zenPage.openLink('Message','"_jsID_"');"">&nbsp;"_tCount_"&nbsp;</td>"
			
			// count (errors)
			set row=row_"<td class=""Lamp LampError Clickable"" title="""_$$$Text("@Number of errors since production start@Number of errors since production start")_""" onclick=""zenPage.openLink('EventLog','"_jsID_"');"">&nbsp;"_tErrorCount_"&nbsp;</td>"
			
			// count (alerts)
			set row=row_"<td class=""Lamp LampAlert Clickable"" title="""_$$$Text("@Number of alerts since production start@Number of alerts since production start")_""" onclick=""zenPage.openLink('EventLog','"_jsID_"');"">&nbsp;"_tAlertCount_"&nbsp;</td>"
			
			set html=html_"<tr>"_row_"</tr>"
		}
		
		set pGroup=##class(%ZEN.Component.html).%New()
		set pGroup.content="<table class=""MonitorTable"" width=""100%"">"_html_"</table>"
		
	} catch ex {
		set ret = ex.AsStatus()
	}
	
	quit ret
}

/// Update page content
Method UpdateContent() As %Status [ ZenMethod ]
{
	set ret = $$$OK
	try {
		set ..NumCategory = 0
		set ..TotalQueuedMessages = 0
		set ..Categories = ""
		set ..ErrorCategories = ""
		
		// get production monitor data
		$$$THROWONERROR(tSC,..GetHostInfo())
		
		// remove elements in "monitor-content" and add new category info
		#dim content As %ZEN.Component.group
		set content=%page.%GetComponentById("monitor-content")
		do content.%RemoveChildren()
		set category=""
		for {
			set category=$o(^||data(category))
			quit:category=""
			set ..Categories = category_","_..Categories
			$$$THROWONERROR(tSC,..DrawCategory(category,.group))
			do content.%AddChild(.group)
		}
		
		// update info
		set ..lastUpdate = $zdt($h,3)
		set %page.%GetComponentById("lastUpdate").value = $zdt($h,3)
		
		// production link
		set pname = ..GetProductionName()
		set plink = %page.%GetComponentById("productionLink")
		set plink.label = $$$Text("Production")_":"
		set plink.caption = pname
		if pname '= "" {
			set plink.href = "EnsPortal.ProductionConfig.zen?PRODUCTION="_pname
		}
		
		// update summary
		$$$THROWONERROR(tSC,..UpdateSummary())
	} catch ex {
		set ret = ex.AsStatus()
	}
	
	&js<zenPage.closeLoadingLayer();>
	
	quit ret
}

/// Update summary content
Method UpdateSummary() As %Status [ ZenMethod ]
{
	set ret = $$$OK
	try {
		// remove old elements in "summary-content" and add new info
		#dim content As %ZEN.Component.group
		set content=%page.%GetComponentById("summary-content")
		do content.%RemoveChildren()
		
		set tQLamp = ..GetQueueColor(..TotalQueuedMessages)
		set html="<tr><td><a class=""link"" target=""new"" href=""EnsPortal.Queues.zen"">"_$$$Text("@Queued Messages@Queued Messages")_"</a></td><td class=""Lamp"" style=""background:"_tQLamp_";"">"_..TotalQueuedMessages_"</td></tr>"
		
		set tSuspended=""
		&sql(SELECT COUNT(*) INTO :tSuspended From Ens.MessageHeader WHERE Status = 5)
		set tQLamp = ..GetQueueColor(tSuspended)
		set html=html_"<tr><td><a class=""link"" target=""new"" href=""EnsPortal.SuspendedMsg.zen"">"_$$$Text("Suspended Messages")_"</a></td><td class=""Lamp"" style=""background:"_tQLamp_";"">"_tSuspended_"</td></tr>"
		
		set obj = ##class(%ZEN.Component.html).%New()
		set obj.content = "<table class=""tpTable"">"_html_"</table>"
		
		do content.%AddChild(obj)
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// Executed after page is created (ZEN)
Method %OnAfterCreatePage() As %Status
{
	set ret=$$$OK
	try { 
		$$$THROWONERROR(tSC, ##super())
		
		// localized titles
		set %page.%GetComponentById("ServiceTitle").value = $$$Text("Service")
		set %page.%GetComponentById("ProcessTitle").value = $$$Text("Process")
		set %page.%GetComponentById("OperationTitle").value = $$$Text("Operation")
		
		$$$THROWONERROR(tSC,..UpdateContent())
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// Javascript on load handler
ClientMethod onloadHandler() [ Language = javascript ]
{
	this.invokeSuper('onloadHandler',[]);
	this.startKeepAlive();
	this.initPopupSuffix();
	
	this.expandedCategory = {};
}

/// Intercept xmlHTTP errors and reload page rather than putting up alert box.
ClientMethod onServerMethodError(err) [ Language = javascript ]
{
	top.document.location.reload();
}

/// Get the (localized) name of the page.
Method %OnGetPageName() As %String
{
	Quit $$$Text("Production Monitor")
}

/// Get the (localized) title string for the page.
Method %OnGetTitle() As %String
{
	Quit $$$Text("Production Monitor")
}

/// Create spanish translation for missing spanish texts in 2013
ClassMethod Translation()
{
	set ^CacheMsg("Ensemble","es","Queued Messages")="Mensajes en cola"
	set ^CacheMsg("Ensemble","es","Nothing")="Nada"
 	set ^CacheMsg("Ensemble","es","Show:")="Mostrar:"
 	set ^CacheMsg("Ensemble","es","Number of errors since production start")="Número de errores desde el inicio de la producción"
 	set ^CacheMsg("Ensemble","es","Number of NACKs")="Número de NACKs"
}

}
