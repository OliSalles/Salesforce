({
   selectRecord : function(component, event, helper){      
    // get the selected record from list  
      var getSelectRecord = component.get("v.oRecord");
    // call the event   
      var compEvent = component.getEvent("oSelectedRecordEvent");
    // set the Selected sObject Record to the event attribute.  
      compEvent.setParams({"recordByEvent" : getSelectRecord });  
    // fire the event  
      compEvent.fire();
    },

    doInit: function(component,event) {
      var oRecord = component.get('v.oRecord');
      var columnNameSearchMatch = component.get('v.columnNameSearchMatch');
      var displayValue = oRecord[columnNameSearchMatch];

      component.set('v.displayValue',displayValue);
    }
})