Class ITB.Production.TestXMLHL7File Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="ITB.Production.TestXMLHL7File" TestingEnabled="true" LogGeneralTraceEvents="true">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Setting Target="Adapter" Name="ShutdownTimeout">1</Setting>
  <Setting Target="Adapter" Name="UpdateTimeout">1</Setting>
  <Item Name="HL7FileXMLService" Category="" ClassName="ITB.HL7.BS.FileXMLService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Host" Name="MessageSchemaCategory">ITB</Setting>
    <Setting Target="Adapter" Name="FilePath">C:\Test\ITB\inHL7</Setting>
    <Setting Target="Host" Name="TargetConfigNames">HL7FileXMLOperation,HL7FileER7Operation</Setting>
    <Setting Target="Host" Name="ArchiveIO">1</Setting>
    <Setting Target="Adapter" Name="FileSpec">*.xml</Setting>
  </Item>
  <Item Name="HL7FileXMLOperation" Category="" ClassName="ITB.HL7.BO.FileXMLOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Adapter" Name="FilePath">C:\Test\ITB\outHL7</Setting>
    <Setting Target="Host" Name="ArchiveIO">1</Setting>
    <Setting Target="Adapter" Name="Charset">UTF-8</Setting>
    <Setting Target="Host" Name="MessageSchemaCategory">ITB</Setting>
  </Item>
  <Item Name="HL7FileER7Service" Category="" ClassName="EnsLib.HL7.Service.FileService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="TargetConfigNames">HL7FileXMLOperation,HL7FileER7Operation</Setting>
    <Setting Target="Adapter" Name="FilePath">C:\Test\ITB\inHL7</Setting>
    <Setting Target="Adapter" Name="FileSpec">*.hl7</Setting>
    <Setting Target="Host" Name="MessageSchemaCategory">ITB</Setting>
  </Item>
  <Item Name="HL7FileER7Operation" Category="" ClassName="EnsLib.HL7.Operation.FileOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="FilePath">C:\Test\ITB\outHL7</Setting>
  </Item>
</Production>
}

/// Location and Revision of this file in Perforce (Auto-updating)
Parameter SrcVer = "$Id$";

}
