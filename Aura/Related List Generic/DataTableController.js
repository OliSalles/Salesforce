({
    doInit: function(component, event, helper) {                       
        helper.getDataHelper(component, event);
    },
    
    getSelectedName: function (component, event, helper) {
        var selectedRows = event.getParam('selectedRows');
        
        // Display that fieldName of the selected rows
        for (var i = 0; i < selectedRows.length; i++){
            //alert("You selected: " + selectedRows[i].Name);
        }
    },
    
    viewAll : function(component, event, helper){
        var evt = $A.get("e.force:navigateToComponent");
        console.log(component.get("v.title"));
        evt.setParams({
            componentDef : "c:DataTable",
            componentAttributes: {
                title       : component.get("v.title"),
                fieldSetList: component.get("v.fieldSetList"),
                objectName  : component.get("v.objectName"),
                filter		: component.get("v.filter"),
                stgRecordId : component.get("v.stgRecordId"),
                count		: component.get("v.count"),
                renderTable	: component.get("v.renderTable"), 
                objectApi	: component.get("v.objectApi"),
                viewAllMode	: true,
                hideCheckboxColumn : component.get("v.hideCheckboxColumn")
            }
        });
        evt.fire();	
	}
})