/// <h2>ITB (InterSystems Tool Box)</h2>
/// 
/// <h3>Reusable Ensemble components</h3>
/// 
/// <h4>Author:</h4>
/// <ul>
///  	<li>alberto.fuentes@intersystems.com</li>
/// </ul>
/// 
/// <h4>Requeriments:</h4>
/// <ul>
///  	<li>IRIS For Health</li>
///     <li>Health Connect</li>
/// </ul>
/// 
/// <h4>Installation:</h4>
/// <ol>
///  	<li>Import /backup/hl7_2_5.Lookup.xml lookup table <small><em>(it's used to convert HL7 XML group names <> EnsLib.HL7.Message group names)</em></small></li>
///  	<li>Import and compile all ITB classes.</li>
/// </ol> 
/// 
/// <h4>Quick start:</h4>
/// <ul>
///  	<li>If you are interested <em>only</em> in HL7 XML <> ER7 transformation see <class>ITB.HL7.Util.Convert</class></li>
/// 	<li>If you want to test HL7 XML services, operations <em>(TCP,HTTP,SOAP,etc.)</em> there's a bunch of <em>testing productions</em> in ITB.Production.*</li>
/// </ul>
/// 
/// <h4>Changelog:</h4>
/// <ul>
///  	<li>0.1   - Initial version</li>
/// 	<li>0.2   - Added ProductionMonitor</li>
/// 	<li>0.3   - ITB.HL7.Format.HL7XMLv2 duplicated group names fix</li>
/// 	<li>0.4   - Added HL7 XML TCP services and operations</li>
/// 	<li>0.5   - Added more config options to XML Services and multi HL7 XML group names mapping</li>
/// 	<li>0.6   - Added TestXMLHL7TCPLoopBack production</li>
/// 	<li>0.7   - Added HL7 XML HTTP services and operations</li>
/// 	<li>0.8   - Added async application HL7 NACK handling, HL7 XML LocalFacilityApplication setting, fix OnGetConnections method</li>
/// 	<li>0.81  - Added additional settings in HL7 NACK handling, HL7 XML LocalFacilityApplication setting enhanced behaviour</li>
/// 	<li>0.9   - ProductionMonitor enhanced, TCPOperation NACKControl fixed</li>
/// 	<li>0.91  - ProductionMonitor Javascript corrections, XMLOperation and XMLHost SETTINGS parameter corrected</li>
/// 	<li>0.92  - HL7 XML: segment fields defined with "@i" datastructure will use field "i" datastructure. Added StripNamespace parameter to XML Service,Operation.</li>
/// 	<li>0.93  - Updated XSD parser and generated HL7 v2.5 Lookup table.</li>
/// 	<li>0.94  - ReplyCodeActions setting added to HL7 XML operations, AckMode and ResponseFrom setting added to HL7 XML services.</li>
/// 	<li>1.0   - NACKMessageViewer tablePane corrected. PORTING parameter added to Info class.</li>
/// 	<li>1.1   - ITB.HL7.Format.HL7XMLv2 2013/2014 changes fixed.</li>
/// 	<li>1.2   - ITB.HL7.Format.HL7XMLv2 XML character output conversion fixed.</li>
/// 	<li>1.3   - Added HL7 XML SOAP service and test production. Updated ITB.HL7.BP.NACKProcess to support custom behaviour.</li>
/// 	<li>1.4   - Added installer, documentation and minor fixes.</li>
/// 	<li>1.5   - Fixed ITB.HL7.Format.HL7XMLv2 2014, added HL7 XML UnitTests, added ITB.Task.PurgeNoRef, updated installer and documentation.</li>
/// 	<li>1.6   - Fixed ITB.HL7.Format.HL7XMLv2, removed Escape/Unescapes.</li>
/// 	<li>1.7   - Fixed ITB.HL7.Format.HL7XMLv2, minor fixes in ITB.EnsPortal.ProductionMonitor.</li>
/// 	<li>1.8   - Fixed ITB.HL7.Format.HL7XMLv2, added support for field values > 32K, performance optimizations.</li>
/// 	<li>1.9   - Removed ITB.HL7.Data.NACK FK to Ens.MessageHeader. Added system task ITB.Task.PurgeNACK to delete async NACK messages that references to non-existing messages.</li>
/// 	<li>2.0   - Fixed ITB.HL7.Format.HL7XMLv2, fixed stream field writing. ITB.inc enhaced, uses max string values depending on 'Enable Long String' setting.</li>
/// 	<li>2.1   - Fixed ITB.HL7.Format.HL7XMLv2, support several segments with large stream fields</li>
///     <li>3.0   - Version for IRIS, Classes added in UDL, ITB.EnsPortal removed (not supported), added Installer manifest</li>
///     <li>3.1   - Installer fixed</li>
/// </ul>
Class ITB.Info Extends %RegisteredObject
{

Parameter VERSION = 3.1;

Parameter PORTING = 2014;

}
