({
    searchHelper : function(component, event, getInputkeyWord) {
        var enableDataBaseSearch = component.get('v.enableDataBaseSearch');

        if(enableDataBaseSearch)
        {
            this.searchDataBase(component, event, getInputkeyWord);
         
        }else{
            this.searchLocal(component, event, getInputkeyWord);  
        }
         
    },
    searchDataBase : function(component, event, getInputkeyWord){
        // Call the apex class method 
        var action = component.get("c.fetchLookUpValues");

        // Set param to method  
        action.setParams({
            'searchKeyWord': getInputkeyWord,
            'ObjectName'   : component.get("v.objectAPIName")
        });

        // Set a callBack    
        action.setCallback(this, function(response) {
            $A.util.removeClass(component.find("mySpinner"), "slds-show");            
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();

                component.set("v.listOfSearchRecords", storeResponse);

                this.removeSelectedElement(component);

            }

        });
        // Enqueue the Action  
        $A.enqueueAction(action); 
    },
    removeSelectedElement : function(component){
        var selectedRecord = component.get('v.selectedRecord');
        var storeResponse  = component.get('v.listOfSearchRecords');
        
        var columnName = component.get('v.columnNameRemoveMatch');

        if(selectedRecord.length!=undefined)
        {
            for(var i=0; i<selectedRecord.length; i++)
            {
                for(var j=0;j<storeResponse.length;j++)
                {
                    if(selectedRecord[i][columnName] == storeResponse[j][columnName])
                    {
                        //remove the found item of the results
                        storeResponse.splice(j,1); 
                        break;  
                    }
                }
            }

            // If storeResponse size is equal 0 ,display No Result Found... message on screen. }
            if (storeResponse.length == 0) {
                component.set("v.Message", 'No Result Found...');

            } else {
                component.set("v.Message", '');
            }

            // Set searchResult list with return value from server.
            component.set("v.listOfSearchRecords", storeResponse);

        }

    }, 
    searchLocal : function(component, event, getInputkeyWord){
        
        var listRecords = component.get('v.listRecords');
        var listOfSearchRecords = component.get('v.listOfSearchRecords');
        var findValue = "";
        var columnName = component.get('v.columnNameSearchMatch');

        listOfSearchRecords = new Array();

        if(listRecords != null)
        {
            if( getInputkeyWord.length > 0 )
            {
                findValue = getInputkeyWord.toUpperCase();
            }

            for(var i=0;i<listRecords.length;i++)
            {
              if(listRecords[i][columnName].toUpperCase().startsWith(findValue))
              {

                listOfSearchRecords.push(listRecords[i]);
              }
            }

            if(listOfSearchRecords != null)
            {
                component.set('v.listOfSearchRecords',listOfSearchRecords);

                this.removeSelectedElement(component);
            }            
        }

    },

    doValidation: function(component,event)
    {
        var selectedRecord = component.get('v.selectedRecord');
        var returnValue;
        var messageError = component.find('messageError');

        if(selectedRecord.length == 0)
        {
            returnValue = false;
            $A.util.addClass(messageError, 'slds-has-error');
            $A.util.removeClass(messageError,'slds-form-element__help');

        }else{
            returnValue = true;
            $A.util.addClass(messageError,'slds-form-element__help');
            $A.util.removeClass(messageError, 'slds-has-error');
        }

        return returnValue;
    }


})