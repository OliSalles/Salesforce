public class Utilities {
  
    
    @AuraEnabled
    public static Map< String, List<String> > getMapAllPickilistaValues() { 
        
        Map< String, List<String> > mapAllPickilistaValues = new Map< String, List<String> >(); 
        
        List<String> listValuesPerDiem    = new List<String>();
        List<String> listValuesNotPerD    = new List<String>();
        
        //Converting set in list
        listValuesPerDiem.addAll(U_Constants.RATE_PICKLIST_PERDIEM);        
        
        if(reqDealSheet.Team__r.Region__c == 'APAC'){
            listValuesNotPerD.addAll(U_Constants.RATE_PICKLIST_APAC);
            
        }else if(reqDealSheet.Team__r.Region__c == 'EMEA'){
            listValuesNotPerD.addAll(U_Constants.RATE_PICKLIST_EMEA);
            
        }else if(reqDealSheet.Team__r.Region__c == 'North America'){
            listValuesNotPerD.addAll(U_Constants.RATE_PICKLIST_NA);
            
        }else if(reqDealSheet.Team__r.Region__c == 'Latin America'){
            listValuesNotPerD.addAll(U_Constants.RATE_PICKLIST_LA);
        
        }
        mapAllPickilistaValues.put( 'Per Diem',  listValuesPerDiem);  
        mapAllPickilistaValues.put( 'Not PerD',  listValuesNotPerD); 
        
/////////////////////////////////////////////////////////////////////////////////////////////////////////////// Utilities Methods
        
        List<List<Schema.PicklistEntry>> listSchemaAllPicklistValues = new List<List<Schema.PicklistEntry>>();
        
        listSchemaAllPicklistValues.add(A_Consultant_Rate__c.Client_Fee_type__c.getDescribe().getPicklistValues());
        
		listSchemaAllPicklistValues.add(A_Consultant_Rate__c.Rate_Type__c.getDescribe().getPicklistValues());
        listSchemaAllPicklistValues.add(A_Consultant_Rate__c.Per_Diem_Terms__c.getDescribe().getPicklistValues());        
        listSchemaAllPicklistValues.add(A_Consultant_Rate__c.Rate_Basis__c.getDescribe().getPicklistValues());
        listSchemaAllPicklistValues.add(A_Consultant_Rate__c.Client_Currency__c.getDescribe().getPicklistValues());
        listSchemaAllPicklistValues.add(A_Consultant_Rate__c.Consultant_Currency__c.getDescribe().getPicklistValues());            
        
        for(List<Schema.PicklistEntry> schemaAllPicklistValues : listSchemaAllPicklistValues){
            
            List<String> listValues = new List<String>();
                
            for(Schema.PicklistEntry schemaPicklistValues : schemaAllPicklistValues){
                
                listValues.add( schemaPicklistValues.getLabel() );
            }
            mapAllPickilistaValues.put(schemaAllPicklistValues[0].getLabel() ,listValues);
        }
        
        return mapAllPickilistaValues;
    }

    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  Objects
    
    public class Errors{
        @AuraEnabled public String  errorsMsg;
        @AuraEnabled public Boolean haveErrors;
        
        public Errors(String errorsMsg, Boolean haveErrors){
            this.errorsMsg  = errorsMsg;
            this.haveErrors = haveErrors;
        }
    }   
}