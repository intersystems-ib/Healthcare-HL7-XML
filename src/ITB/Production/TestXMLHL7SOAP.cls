Class ITB.Production.TestXMLHL7SOAP Extends Ens.Production
{

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id$";

XData ProductionDefinition
{
<Production Name="ITB.Production.TestXMLHL7SOAP" LogGeneralTraceEvents="false">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="ITB.HL7.BS.SOAPXMLService" Category="SOAP,XML" ClassName="ITB.HL7.BS.SOAPXMLService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="ArchiveIO">1</Setting>
    <Setting Target="Host" Name="TargetConfigNames">FileXMLOperation</Setting>
    <Setting Target="Adapter" Name="EnableStandardRequests">1</Setting>
  </Item>
  <Item Name="FileXMLOperation" Category="" ClassName="ITB.HL7.BO.FileXMLOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="FilePath">C:\Test\ITB\outHL7</Setting>
  </Item>
</Production>
}

}
