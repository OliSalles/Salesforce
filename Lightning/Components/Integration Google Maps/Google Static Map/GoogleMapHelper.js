({
    getCoordinates : function(component, event) {
        
        var action = component.get("c.getCoordinates");
        
        action.setCallback(this, function(response) {
            
            if(response.getState() === "SUCCESS") {
                
                var returnValue = response.getReturnValue();           
                
                console.log(returnValue);
                                  
                component.set("v.mapUrl", returnValue);    
            }   
        });
        $A.enqueueAction(action);    
    }
})