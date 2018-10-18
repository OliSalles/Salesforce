({
    doInit: function (component, event) {
        
        var recordId = component.get("v.recordId");
        
        var action    = component.get("c.checkContactAddress");
        action.setParams({
            "recordId": recordId
        });
        
        action.setCallback(this, function (response) {            
            if(response.getState() === "SUCCESS") {
                
                component.set("v.showAlert", response.getReturnValue());    
            }   
        });
        $A.enqueueAction(action);
    },
    
    searchAddress: function (component, event) {
        
        var searchKey = component.get("v.searchKey");
        
        var action    = component.get("c.getAddressAutoComplete");
        action.setParams({
            "input": searchKey
        });
        
        action.setCallback(this, function (response) {
            
            if(response.getState() === "SUCCESS") {
                
                var returnValue = JSON.parse(response.getReturnValue());               
                var addresses   = [];                
                
                for( var i = 0; i < returnValue.predictions.length; i++ ){                                          
                    addresses.push({
                        value: returnValue.predictions[i].description,
                        placeId: returnValue.predictions[i].place_id                         
                    });                      
                }           
                component.set("v.filteredOptions", addresses);    
            }   
        });
        $A.enqueueAction(action);
    },
    
    selected: function (component, event) {
        
        var selectedItem = event.currentTarget; // Get the target object
        var index        = selectedItem.dataset.record;   // Get its value i.e. the index
        var place        = component.get("v.filteredOptions")[index]; // Use it retrieve the store record
        
        component.set("v.searchKey", place.value);
        component.set("v.placeId",   place.place_id );
        component.set("v.filteredOptions", []);
    },
    
    save: function (component, event) {
        
        var placeId  = component.get("v.placeId");
        var recordId = component.get("v.recordId");
        
        var action   = component.get("c.getAddressDetails");
        action.setParams({
            "placeId": place.placeId,
            "recordId": recordId
        });
        action.setCallback(this, function(response){
            
            var state = response.getState();
            
            if(state === 'SUCCESS'){
                var returnValue = response.getReturnValue();                 
                var toastEvent  = $A.get("e.force:showToast");
                
                if(returnValue){                    
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "The property's info has been saves.",
                        "type": "Success"
                    });
                }else{
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": "The property's info has not saved.",
                        "type": "Error"
                    });
                }
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    }
})