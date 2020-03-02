/// HL7 XML services common class
Class ITB.HL7.XMLHost Extends Ens.Host
{

Property TargetConfigNames As %String(MAXLEN = 1000);

Property SearchTableClass As %String(MAXLEN = 128) [ InitialExpression = "EnsLib.HL7.SearchTable" ];

Property MessageSchemaCategory As %String(MAXLEN = 1000) [ InitialExpression = "2.5" ];

Parameter SETTINGS = "SearchTableClass::selector?context={Ens.ContextSearch/SearchTableClasses?host=EnsLib.HL7.Service.Standard},MessageSchemaCategory:Basic:selector?context={Ens.ContextSearch/SchemaCategories?host=EnsLib.HL7.Service.Standard}";

}
