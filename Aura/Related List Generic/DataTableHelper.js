({
    getDataHelper : function(component, event) {
        
        var action       = component.get("c.getRecords");
        
        var objectApi    = component.get("v.objectApi");
        var fieldSetList = component.get("v.fieldSetList");
        var filter       = component.get("v.filter");
        var filter2      = component.get("v.filter2");
        var stgRecordId  = component.get("v.stgRecordId");
        
        var recordList   = [];
        
        action.setParams({
            strObjectName   : objectApi,
            strFieldSetName : fieldSetList,
            filter          : filter,
            filter2         : filter2,
            recordId        : stgRecordId
        });
        
        action.setCallback(this, function(response){
            var state = response.getState();
            var rows  = [];
            
            if(state === 'SUCCESS'){
                
                var returnValue = response.getReturnValue();
                var count = returnValue.lstDataTableData.length;
                
                if(count > 0){
                   component.set("v.count", count); 
                   component.set("v.renderTable", true);                     
                }
                
                if( (!component.get("v.viewAllMode")) && count > 4){
                    recordList = returnValue.lstDataTableData.slice(0, 3); 
                
                }else{
                    recordList = returnValue.lstDataTableData;
                }
                    
                
                var mapDataType = returnValue.mapDataType;
           
                // For Related list
                var url = window.location.toString().split("lightning/r/")[0];

                // For view all mode
                var url = url.split("one/one")[0];     
                
                //Separate Rows from Table
                recordList.forEach(function(row){  
                    //Separate fields from Rows
                    for(var field in row){ 
                        
                        //Find relationship fields
                        if(field == "RecordType"){
                            row[field] = row[field].Name;
                        }
                        else if(field.includes('__r')){
                            
                            var lookupField = field.replace("__r", "__c");
                            
                            row[lookupField] = url + row[field].Id;
                            
                            row[field] = row[field].Name;
                        } 
                        else if(mapDataType[field] == 'percent'){
                            row[field] = row[field] / 100;
                        }   
                    }
                    //For de Name field
                    row.Id = url + row.Id;
                    
                    rows.push(row); 
                });     
                
                component.set("v.mydata",    rows);  
                component.set("v.mycolumns", returnValue.lstDataTableColumns);                                                
                
            }else if(state === 'ERROR'){
                var errors = response.getError();
                
                if(errors){
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }else{
                console.log("Something went wrong, Please check with your admin");
            }
        });
        $A.enqueueAction(action);   
    }
})