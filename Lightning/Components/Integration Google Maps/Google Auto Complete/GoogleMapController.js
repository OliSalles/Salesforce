({
    doInit: function(component, event, helper) {        
        helper.doInit(component, event);
    },
    
    searchAddress: function (component, event, helper) {    
        var count = component.get("v.count");
        count++;

        //Makes a request every 4 characters.
        if( count%4 == 0 )
            helper.searchAddress(component, event);    
        
        component.set("v.count", count);   
    },
    
    selected: function(component, event, helper) {        
        helper.selected(component, event);
    },
    
    save: function(component, event, helper) {        
        helper.save(component, event);
    }
})