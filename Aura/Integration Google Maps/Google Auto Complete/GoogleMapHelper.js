({
    doInit: function (component, event) {
        
        var recordId  = component.get("v.recordId");
        
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
        
        component.set("v.searchKey", place.value );
        component.set("v.placeId",   place.placeId );
        component.set("v.filteredOptions", []);
        
        //var action = component.get("c.getCoordinates");
        
        var action = component.get("c.placeSelected");
        action.setParams({
            "placeId":place.placeId
        });
        action.setCallback(this, function(response){
            
            if(response.getState() === 'SUCCESS'){
                var returnValue = response.getReturnValue();       
                
                console.log("returnValue => ", returnValue);
                
                if(returnValue){                                        
                    component.set("v.responsePlaces", returnValue);
                    
                    var listAddressComponents = returnValue.result.address_components;
                    
                    listAddressComponents.forEach(putAddressComponents)
                    
                    function putAddressComponents(item, indice) {
                        
                        if(listAddressComponents[indice].types[0] == 'postal_code')
                            component.set("v.postalCodeValue" , listAddressComponents[indice].long_name +', '+ listAddressComponents[indice].short_name ); 
                        
                        else if(listAddressComponents[indice].types[0] == 'administrative_area_level_2')
                            component.set("v.cityValue" ,listAddressComponents[indice].long_name +', '+ listAddressComponents[indice].short_name );
                        
                        else if(listAddressComponents[indice].types[0] == 'administrative_area_level_1')               
                            component.set("v.stateValue" ,listAddressComponents[indice].long_name +', '+ listAddressComponents[indice].short_name );
                        
                        else if(listAddressComponents[indice].types[0] == 'country')
                            component.set("v.countryValue" ,listAddressComponents[indice].long_name +', '+ listAddressComponents[indice].short_name );                         
                    }
                    
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "message": "The property's info has not saved.",
                        "type": "Error"
                    });
                    toastEvent.fire();
                }                
            }
        });
        $A.enqueueAction(action);                
    },
    
    save: function (component, event) {
        
        var responsePlaces      = component.get("v.responsePlaces");
        var JSONresponsePlaces  = JSON.stringify(responsePlaces);
        
        var placeId     = component.get("v.placeId");
        var recordId    = component.get("v.recordId");
        
        var objectName  = component.get("v.objectName");
        
        var postalCode  = component.get("v.postalCode");
        var city        = component.get("v.city");
        var state       = component.get("v.state");
        var country     = component.get("v.country");
        
        var latitude    = component.get("v.latitude");
        var longitude   = component.get("v.longitude");
        
        var formattedAddress = component.get("v.formattedAddress");
        
        var action = component.get("c.saveAddress");
        action.setParams({
               "placeId":placeId,
              "recordId":recordId,
            "objectName":objectName,
    "JSONresponsePlaces":JSONresponsePlaces,
            "postalCode":postalCode,
                  "city":city,
                 "state":state,
               "country":country,
      "formattedAddress":formattedAddress,
              "latitude":latitude,
             "longitude":longitude
        });
        action.setCallback(this, function(response){
            
            if(response.getState() === 'SUCCESS'){
                var returnValue = response.getReturnValue();                 
                var toastEvent  = $A.get("e.force:showToast");
                
                if(returnValue){                    
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "The property's info has been saves.",
                        "type": "Success"
                    });
                    window.location.reload();
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