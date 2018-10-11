public class Utilities {
  
/////////////////////////////////////////////////////////////////////////////////////////////////////////////// Utilities Methods

    @AuraEnabled
    public static List< List<Schema.PicklistEntry> > getMapAllPickilistaValues() {         
                
        List< List<Schema.PicklistEntry> > listSchemaAllPicklistValues = new List< List<Schema.PicklistEntry> >();
        
        listSchemaAllPicklistValues.add(<OBJECT API>.<FIELD API>.getDescribe().getPicklistValues());
        listSchemaAllPicklistValues.add(<OBJECT API>.<FIELD API>.getDescribe().getPicklistValues());        
        
        for(List<Schema.PicklistEntry> schemaAllPicklistValues : listSchemaAllPicklistValues){
            
            List<String> listValues = new List<String>();
                
            for(Schema.PicklistEntry schemaPicklistValues : schemaAllPicklistValues){
                
                listValues.add( schemaPicklistValues.getLabel() );
            }
            mapAllPickilistaValues.put(schemaAllPicklistValues[0].getLabel() ,listValues);
        }        
        return listSchemaAllPicklistValues;
    }
    
///////////////////////////////////////////////////////////////////////////////////////////////////////////////  Objects
    
    public class Errors{
        @AuraEnabled public String  errorsMsg;
        @AuraEnabled public Boolean haveErrors;
        
        public Errors(String errorsMsg, Boolean haveErrors){
            this.errorsMsg  = errorsMsg;
            this.haveErrors = haveErrors;
        }
    }   
}