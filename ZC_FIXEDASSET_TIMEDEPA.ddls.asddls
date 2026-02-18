@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Fixed Asset Time-Dependent Data - Consumption View'
@Metadata.allowExtensions: true
@UI.headerInfo: {
  typeName: 'Time-Dependent Data',
  typeNamePlural: 'Time-Dependent Data'
}
define view entity ZC_FIXEDASSET_TIMEDEPA
  as projection on ZI_FIXEDASSET_TIMEDEPA
{
  key TimeDependentUUID,
  key CompanyCode,
  key AssetMainNumber,
  key AssetSubNumber,
  
  @UI.lineItem: [{ position: 10, importance: #HIGH }]
  @UI.identification: [{ position: 10 }]
  key ValidityStartDate,
  
  @UI.lineItem: [{ position: 20, importance: #MEDIUM }]
  @UI.identification: [{ position: 20 }]
  ValidityEndDate,
  
  @UI.lineItem: [{ position: 30, importance: #HIGH }]
  @UI.identification: [{ position: 30 }]
  @Consumption.valueHelpDefinition: [{
    entity: { name: 'I_CostCenter', element: 'CostCenter' }
  }]
  CostCenter,
  
  @UI.lineItem: [{ position: 40, importance: #HIGH }]
  @UI.identification: [{ position: 40 }]
  @Consumption.valueHelpDefinition: [{
    entity: { name: 'I_ProfitCenter', element: 'ProfitCenter' }
  }]
  ProfitCenter,
  
  @UI.identification: [{ position: 50 }]
  WBSElement,
  
  @UI.identification: [{ position: 60 }]
  InternalOrder,
  
  @UI.lineItem: [{ position: 50, importance: #MEDIUM }]
  @UI.identification: [{ position: 70 }]
  AssetLocation,
  
  @UI.identification: [{ position: 80 }]
  RoomNumber,
  
  @UI.identification: [{ position: 90 }]
  PersonResponsible,
  
  @UI.identification: [{ position: 100 }]
  Segment,
  
  @UI.identification: [{ position: 110 }]
  FunctionalArea,
  
  LocalLastChangedAt,
  
  // Associations
  _FixedAsset : redirected to parent ZC_FIXEDASSET,
  _CostCenter,
  _ProfitCenter
}