public class DataTableCtrl {

    public static Schema.FieldSet fieldSetObj;
    
    @AuraEnabled
    public static DataTableResponse getRecords(String strObjectName, String strFieldSetName, String filter, String filter2, String recordId){ 
        
        //To hold the table hearders  
        List<DataTableColumns> lstDataColumns = new List<DataTableColumns>();
        
        //Field to be queried - fetched from fieldset  
        List<String> lstFieldsToQuery = new List<String>();
        
        //The final wrapper response to return to component  
        DataTableResponse response = new DataTableResponse();
        
        Map<String, String> mapDataTypes = new Map<String, String>();

        //Get the fields from FieldSet                    
        fieldSetObj = Schema.getGlobalDescribe().get(strObjectName).getDescribe().FieldSets.getMap().get(strFieldSetName);
        
        for( Schema.FieldSetMember eachFieldSetMember : fieldSetObj.getFields() ){

            String dataType  		= String.valueOf( eachFieldSetMember.getType() ).toLowerCase();
            String fieldName        = String.valueOf( eachFieldSetMember.getFieldPath() );
            String fieldNameToQuery = String.valueOf( eachFieldSetMember.getFieldPath() );
            
            //We do not get the exact type from schema object which matches to lightning:datatable component structure 
            //This way we can set the type of a column
            
            System.debug('dataType =====> ' + dataType);
            
            if(dataType == 'datetime'){
                dataType = 'date';            
            }            
            else if(fieldName == 'RecordTypeId'){
                fieldName = 'RecordType';   
                fieldNameToQuery = 'RecordType.Name';
            }
            else if(dataType == 'reference'){ 
                dataType  = 'url'; 
                fieldName = fieldName.replace('__c', '__r'); 
                fieldNameToQuery = fieldName.replace('__c', '__r')+'.Name'; 
            }  
            else if(dataType == 'double' || dataType == 'integer'){
                dataType = 'number';
            }
            else if(fieldName == 'Name'){
                dataType = 'url';             
            }
            
            mapDataTypes.put(fieldName, dataType);
            
            lstFieldsToQuery.add(fieldNameToQuery);
            
            //Create a wrapper instance and store label, fieldname and type.
            DataTableColumns datacolumns = new DataTableColumns( String.valueOf(eachFieldSetMember.getLabel()) , fieldName, dataType); 
            
            lstDataColumns.add(datacolumns);
        }
        
        //Form an SOQL to fetch the data - Set the wrapper instance and return as response
        if(! lstDataColumns.isEmpty() ){ 
            
            response.lstDataTableColumns = lstDataColumns;

            String query = 'SELECT Id, ' + String.join(lstFieldsToQuery, ',') + 
                            ' FROM '     + strObjectName + ' ' + filter + '\'' + recordId + '\' ' + filter2;    
            
            System.debug('query ===> ' + query);
            try{
            	response.lstDataTableData = Database.query(query);
                response.mapDataType      = mapDataTypes;
                
            }catch(Exception e){
                system.debug('Error => ' + e);
            }
        }        
        return response;
    }
    
    
    @AuraEnabled
    public static List<ListView> getListViews(String objectName) {
        
        List<ListView> listviews = [ SELECT Id, Name 
                                       FROM ListView 
                                      WHERE SobjectType =: objectName];
        
        System.debug('listviews => ' + listviews);
    
        // Perform isAccessible() check here
        return listviews;
    }
    
    
    /////////////////////////////////Wrapper class to hold Columns with headers ////////////// Objects
    public class DataTableColumns {
        @AuraEnabled public String label     {get;set;}
        @AuraEnabled public String fieldName {get;set;}
        @AuraEnabled public String type      {get;set;}
        @AuraEnabled public TypeAttributes typeAttributes {get;set;} 
        @AuraEnabled public CellAttributes cellAttributes {get;set;} 
        
        //Create and set three variables label, fieldname and type as required by the lightning:datatable
        public DataTableColumns(String label, String fieldName, String type ){
           
            if(fieldName == 'Name'){
                this.fieldName = 'Id';
                this.typeAttributes = new TypeAttributes(fieldName);
            
            }else if(type == 'url'){ 
            	this.fieldName      = fieldName.replace('__r', '__c'); 
                this.typeAttributes = new TypeAttributes(fieldName);
            }else{
                this.fieldName      = fieldName;
            }
            this.label = label;
            this.type  = type; 
            this.cellAttributes = new CellAttributes('left');
        }
    }
    
    public class TypeAttributes {
        @AuraEnabled public String target {get;set;}
        @AuraEnabled public Label  label  {get;set;}
        
        public TypeAttributes(String fieldName){
            
            this.label  = new Label(fieldName);
            this.target = '_blank';
        }
    }
    
    public class Label {
        @AuraEnabled public String fieldName {get;set;}
        
        public Label(String fieldName){
            this.fieldName = fieldName;
        }
    }
    
    public class CellAttributes  {
        @AuraEnabled public String alignment  {get;set;}
        
        public CellAttributes(String alignment ){
            this.alignment  = alignment ;
        }
    }
    
    //Wrapper calss to hold response - This response is used in the lightning:datatable component
    public class DataTableResponse {
        @AuraEnabled public List<DataTableColumns> lstDataTableColumns {get;set;}
        @AuraEnabled public List<SObject>          lstDataTableData    {get;set;}         
        @AuraEnabled public Map<String, String>    mapDataType         {get;set;} 
        
        public DataTableResponse(){
            lstDataTableColumns = new List<DataTableColumns>();
            lstDataTableData    = new List<SObject>();
        }
    } 
}