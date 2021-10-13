/// 
/// Installer for HealthCare-HL7-XML
/// 
/// This class contains:
/// - Methods to run a regular installation (no zpm)
/// 
/// See README.md for installation instructions
Class ITB.Installer
{

/// Create environment
/// Use this option when you need to automate the creation of an environment (e.g. a test namespace and databases)
Parameter CreateEnvironment = "no";

/// Run an install with no package manager (no ZPM)
Parameter RunNoZPMInstall = "no";

/// Namespace (used when CreateEnvironment)
Parameter Namespace = "HL7XML";

/// Base application path (used when CreateEnvironment)
Parameter BasePath = "/opt/hl7xml/app";

/// Data db path (used when CreateEnvironment)
Parameter DataDBPath = "/opt/hl7xml/db/data";

/// Code db path (used when CreateEnvironment)
Parameter CodeDBPath = "/opt/hl7xml/db/code";

/// Manifest: Create Environment
XData CreateEnvironmentManifest
{
<Manifest>
	<Log Text="Creating namespace ${Namespace}" Level="0"/> 
	<Namespace Name="${Namespace}" Create="yes" Ensemble="1"> 
		<Configuration> 
			<Database Name="${Namespace}-DATA" Dir="${DataDBPath}" Create="yes" MountRequired="true" Resource="%DB_DEFAULT" PublicPermissions="RW" MountAtStartup="true"/> 
			<Database Name="${Namespace}-APP" Dir="${CodeDBPath}" Create="yes" MountRequired="true" Resource="%DB_DEFAULT" PublicPermissions="RW" MountAtStartup="true"/> 
		</Configuration>
	</Namespace>
</Manifest>
}

/// Manifest: Regular Install (No PackageManager)
XData RunNoZPMInstallManifest
{
<Manifest>
	<Var Name="SourcePath" Value="${BasePath}/src/"/> 
	<Log Text="Using namespace ${Namespace}" Level="0"/> 
	<Namespace Name="${Namespace}" Create="no" Ensemble=""> 
		<Import File="${SourcePath}ITB.inc" Recurse="0" Flags="cuk" />
		<Import File="${SourcePath}" Recurse="1" Flags="cuk" />
		<Import File="${BasePath}/unittest/src/" Recurse="1" Flags="cuk" />
	</Namespace>
</Manifest>
}

ClassMethod RunCreateEnvironmentManifest(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
   Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "CreateEnvironmentManifest")
}

ClassMethod RunNoZPMInstallManifest(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
   Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "RunNoZPMInstallManifest")
}

/// Installer entry point (no ZPM). This is the classic installation method :D 
/// Use this when you need to run a regular installation: no create environment, no zpm
/// 
/// - pBasePath: base application path (where it has been downloaded) 
ClassMethod Run(pBasePath As %String) As %Status
{
	set ret = $$$OK
	try {
		set vars("BasePath") = ##class(%File).NormalizeDirectory(pBasePath)
		set vars("Namespace") = $namespace
  		set vars("CreateEnvironment") = "no"
		set vars("RunNoZPMInstall") = "yes"
  		$$$ThrowOnError(..RunWithParams(.vars))
	} catch ex {
		set ret = ex.AsStatus()
	}
	quit ret
}

/// Installer entry point (no ZPM).
/// Use this when you need to control all installation parameters.
/// 
/// You can pass parameters using vars:
/// - CreateEnvironment, RunNoZPMInstall, Namespace, BasePath, DataDBPath, CodeDBPath 
ClassMethod RunWithParams(ByRef vars) As %Status
{
	set ret = $$$OK
	set previousNamespace = $namespace

    try { 
        do ..Log("START INSTALLER") 

		// set default values for installer variables
        for ivar="CreateEnvironment","RunNoZPMInstall","Namespace","BasePath","DataDBPath","CodeDBPath" {
            if '$data(vars(ivar)) set vars(ivar)=$parameter($classname(), ivar)
        }

		// check interoperability enabled on namespace
		if ((vars("CreateEnvironment") '= "yes")&&('##class(%EnsembleMgr).IsEnsembleNamespace(vars("Namespace")))) {
			$$$ThrowStatus($$$ERROR($$$GeneralError, "Namespace "_vars("Namespace")_" has no Interoperability enabled"))
		}
		
		// create environment
		if vars("CreateEnvironment") = "yes" {
			$$$ThrowOnError(..RunCreateEnvironmentManifest(.vars))
		}

		// run no ZPM install
		if vars("RunNoZPMInstall") = "yes" {
			$$$ThrowOnError(..RunNoZPMInstallManifest(.vars))

			// check installation: version, unitests
			set $namespace = vars("Namespace")
			$$$ThrowOnError(..RunTests(vars("BasePath")))
		}
		
        do ..Log("INSTALLER SUCCESS")

    } catch ex { 
        set sc = ex.AsStatus() 
        write $System.Status.GetErrorText(sc),! 
        do $SYSTEM.Process.Terminate($JOB,1) 
    }

	set $namespace = previousNamespace
    quit ret
}

/// Run Tests. This method is called right after a regular no zpm installation
ClassMethod RunTests(pBasePath As %String) As %Status
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
		set ^UnitTestRoot = ##class(%File).NormalizeDirectory("unittest/src/ITB/UnitTest", pBasePath)
		set userParam = "v="_##class(ITB.Info).#VERSION
		$$$ThrowOnError(##class(%UnitTest.Manager).RunTest("","/nodelete",userParam))
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
