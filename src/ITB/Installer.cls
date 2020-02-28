Class ITB.Installer
{

Parameter BasePath = "/opt/IRIS-HL7-XML/";

XData Install
{
<Manifest>
	<If Condition='"${RunDir}"=""'>
    	<Var Name="BasePath" Value="${#BasePath}"/>
		<Else>
			<Var Name="BasePath" Value="${RunDir}"/>
		</Else>
	</If>
    <Var Name="SourcePath" Value="${BasePath}src/"/> 
    <Var Name="ConfigPath" Value="${BasePath}config/"/>
    <Log Text="Using namespace ${Namespace}" Level="0"/>
    <Namespace Name="${Namespace}" Create="no" Ensemble=""> 
        <Import File="${SourcePath}ITB.inc" Recurse="1" Flags="cuk" />
        <Import File="${SourcePath}" Recurse="1" Flags="cuk" />
        <Import File="${ConfigPath}" Recurse="1" Flags="cuk" />
    </Namespace>
</Manifest>
}

ClassMethod RunManifest(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
   #; Let XGL document generate code for this method. 
   Quit ##class(%Installer.Manifest).%Generate(%compiledclass,
      %code, "Install")
}

/// Entry point    
ClassMethod Run(RunDir As %String, Namespace As %String) As %Status
{
    try { 
        write "START INSTALLER",! 
		if $Get(Namespace) ="" {
			set Namespace = $Namespace
		}
		if '##class(%EnsembleMgr).IsEnsembleNamespace(Namespace) {
			set etext = "'"_Namespace_"' Namespace has no Interoperability enabled"
			Throw ##class(%Exception.General).%New("ERROR","5001",,etext)
		}
        set vars("Namespace") = Namespace
		if ($Get(RunDir) '="") {set vars("RunDir") = ##class(%File).NormalizeDirectory(RunDir)}
        set sc = ..RunManifest(.vars) 
        if sc {
            do ..Log("Install Files ended")
            $$$THROWONERROR(sc, ..Check())
            write !,"INSTALLER SUCCESS",!
        } else {
            do $SYSTEM.Process.Terminate($JOB,1)
        }
    } catch ex { 
        set sc = ex.AsStatus() 
        write $System.Status.GetErrorText(sc),! 
        do $SYSTEM.Process.Terminate($JOB,1) 
    } 
    quit sc
}

/// Check installation
ClassMethod Check() As %Status
{
	set ret = $$$OK
	set oldRoot = $get(^UnitTestRoot)
	try {
		do ..Log("ITB Checking started")
		set info = "ITB.Info"
		set exist = ##class(%Dictionary.ClassDefinition).%ExistsId("ITB.Info")
		if 'exist $$$ThrowStatus($$$ERROR($$$GeneralError,"ITB.Info does not exist!"))
		do ..Log("__"_info_".VERSION="_$parameter(info,"VERSION"))
		do ..Log("ITB Checking ended")
		
		do ..Log("ITB UnitTest",,0)
		set ^UnitTestRoot = ##class(%File).NormalizeDirectory("", ..#BasePath)
		set userParam = "v="_##class(ITB.Info).#VERSION
		$$$THROWONERROR(sc, ##class(%UnitTest.Manager).RunTest("src/ITB/UnitTest",,userParam))
		do ..Log("",0,1)
		do ..Log("ITB UnitTest ended")
	} catch ex {
		set ret = ex.AsStatus()
	}
	set ^UnitTestRoot = oldRoot
	quit ret
}

/// Uninstalls ITB.
/// *WARNING* it actually deletes classes!!
ClassMethod Uninstall() As %Status
{
	set ret = $$$OK
	try {
		do ..Log("Deleting includes...")
		$$$ThrowOnError(##class(%RoutineMgr).Delete("ITB.inc"))
		
		do ..Log("Deleting HL7 schemas...")
		$$$ThrowOnError(##class(EnsLib.HL7.SchemaDocument).Delete("ITB.HL7"))
		
		do ..Log("Deleting lookup tables...")
		&sql(delete from Ens_Util.LookupTable where TableName='hl7_2.5' or TableName='hl7_2.6' or TableName='hl7_ITB')
		
		do ..Log("Deleting classes...")
		$$$ThrowOnError($system.OBJ.DeletePackage("ITB"))
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// Log a message
/// pText - Text message
/// pTimeStamp - Add a timestamp
/// pNewLine - Add a new line
ClassMethod Log(pText As %String, pTimeStamp As %Boolean = 1, pNewLine As %Boolean = 1)
{
	write $case(pTimeStamp,1:"["_$zdt($h,3)_"] ",:"")_pText_$case(pNewLine,1:$$$NL,:"")
}

}
