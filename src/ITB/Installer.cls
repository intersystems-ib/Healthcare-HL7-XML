Class ITB.Installer
{

Parameter BasePath = "/opt/hl7xml/app";

Parameter Namespace = "HL7XML";

Parameter CreateNamespace = "no";

Parameter DataDBPath = "/opt/hl7xml/db/data";

Parameter CodeDBPath = "/opt/hl7xml/db/code";

XData Install
{
<Manifest>
	<Var Name="SourcePath" Value="${BasePath}/src/"/> 
    <Var Name="ConfigPath" Value="${BasePath}/config/"/>
    <If Condition='"${CreateNamespace}"="yes"'>
        <Log Text="Creating namespace ${Namespace}" Level="0"/> 
        <Namespace Name="${Namespace}" Create="yes" Ensemble="1"> 
            <Configuration> 
                <Database Name="${Namespace}-DATA" Dir="${DataDBPath}" Create="yes" MountRequired="true" Resource="%DB_DEFAULT" PublicPermissions="RW" MountAtStartup="true"/> 
                <Database Name="${Namespace}-APP" Dir="${CodeDBPath}" Create="yes" MountRequired="true" Resource="%DB_DEFAULT" PublicPermissions="RW" MountAtStartup="true"/> 
            </Configuration>
            <Import File="${SourcePath}ITB.inc" Recurse="0" Flags="cuk" />
            <Import File="${SourcePath}" Recurse="1" Flags="cuk" />
        	<Import File="${ConfigPath}" Recurse="1" Flags="cuk" />
        </Namespace>
    </If>
    <If Condition='"${CreateNamespace}"="no"'>
        <Log Text="Using namespace ${Namespace}" Level="0"/> 
        <Namespace Name="${Namespace}" Create="no" Ensemble=""> 
            <Import File="${SourcePath}ITB.inc" Recurse="0" Flags="cuk" />
            <Import File="${SourcePath}" Recurse="1" Flags="cuk" />
        	<Import File="${ConfigPath}" Recurse="1" Flags="cuk" />
        </Namespace>
    </If>
</Manifest>
}

/// This is a method generator whose code is generated by XGL
ClassMethod RunManifest(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
   Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "Install")
}

/// Installer entry point
/// Use this in case you want to automate container installations
ClassMethod RunWithParams(ByRef vars) As %Status
{
	set ret = $$$OK
	set previousNamespace = $namespace

    try { 
        write "START INSTALLER",! 
		
		// set default values for installer variables
        for ivar="BasePath","Namespace","CreateNamespace","CreateDB","DataDBPath","CodeDBPath" {
            if '$data(vars(ivar)) set vars(ivar)=$parameter($classname(), ivar)
        }
		$$$ThrowOnError(..RunManifest(.vars))

		// check interoperability enabled on namespace
		if '##class(%EnsembleMgr).IsEnsembleNamespace(vars("Namespace")) {
			$$$ThrowStatus($$$ERROR($$$GeneralError, "Namespace "_vars("Namespace")_" has no Interoperability enabled"))
		}

		// check installation: version, unitests
		set $namespace = vars("Namespace")
		$$$ThrowOnError(..Check())

        write !,"INSTALLER SUCCESS",!

    } catch ex { 
        set sc = ex.AsStatus() 
        write $System.Status.GetErrorText(sc),! 
        do $SYSTEM.Process.Terminate($JOB,1) 
    }

	set $namespace = previousNamespace
    quit ret
}

/// Backwards compatible installer entry point
ClassMethod Run(RunDir As %String) As %Status
{
	set ret = $$$OK
	try {
		set vars("BasePath") = ##class(%File).NormalizeDirectory(RunDir)
		set vars("Namespace") = $namespace
  		set vars("CreateNamespace") = "no"
  		$$$ThrowOnError(..RunWithParams(.vars))
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// Check installation
ClassMethod Check() As %Status
{
	set ret = $$$OK
	set oldRoot = $get(^UnitTestRoot)
	try {
		do ..Log("Version checking")
		set info = "ITB.Info"
		set exist = ##class(%Dictionary.ClassDefinition).%ExistsId("ITB.Info")
		if 'exist $$$ThrowStatus($$$ERROR($$$GeneralError,"ITB.Info does not exist!"))
		do ..Log("__"_info_".VERSION="_$parameter(info,"VERSION"))
		do ..Log("Version checking ended")
		
		do ..Log("UnitTest",,0)
		set ^UnitTestRoot = ##class(%File).NormalizeDirectory("", ..#BasePath)
		set userParam = "v="_##class(ITB.Info).#VERSION
		$$$ThrowOnError(##class(%UnitTest.Manager).RunTest("src/ITB/UnitTest",,userParam))
		do ..Log("",0,1)
		do ..Log("UnitTest ended")
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