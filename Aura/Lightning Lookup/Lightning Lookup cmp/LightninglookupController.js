({  
  init : function(component, event, helper){           

    //check if necessary to enable the database search
    var listRecords = component.get('v.listRecords');

    if(listRecords != null) {
      if(listRecords.length >0 ) {
        component.set('v.enableDataBaseSearch',false);
      }else{
        component.set('v.enableDataBaseSearch',true);
      }
    }    
  },

  onfocus : function(component,event,helper) {
    
    $A.util.addClass(component.find("mySpinner"), "slds-show");
    var forOpen = component.find("searchRes");

    $A.util.addClass(forOpen, 'slds-is-open');
    $A.util.removeClass(forOpen, 'slds-is-close');

    // Get Default 5 Records order by createdDate DESC  
    var getInputkeyWord = '';

    helper.searchHelper(component, event, getInputkeyWord);
  },

  onblur : function(component,event,helper) { 
    component.set('v.SearchKeyWord',"");         
    
    var forclose = component.find("searchRes");

    $A.util.addClass(forclose, 'slds-is-close');
    $A.util.removeClass(forclose, 'slds-is-open');
  },

  keyPressController : function(component, event, helper) {
    // get the search Input keyword   
    var getInputkeyWord = component.get("v.SearchKeyWord");
    // check if getInputKeyWord size id more then 0 then open the lookup result List and 
    // else close the lookup result List part.   
    if( getInputkeyWord.length > 0 ) {
      var forOpen = component.find("searchRes");
      $A.util.addClass(forOpen, 'slds-is-open');
      $A.util.removeClass(forOpen, 'slds-is-close');

      // Ronaldo S.A.
      helper.searchHelper(component,event,getInputkeyWord);

    }else{        
      component.set("v.listOfSearchRecords", null ); 
      
      var forclose = component.find("searchRes");

      $A.util.addClass(forclose, 'slds-is-close');
      $A.util.removeClass(forclose, 'slds-is-open');
    }
  },

  // function for clear the Record Selection 
  clear :function(component,event,heplper) {
    var pillTarget = component.find("lookup-pill");
    var lookUpTarget = component.find("lookupField"); 
    var lookupIconSearch = component.find("lookupIconSearch");

    $A.util.addClass(lookupIconSearch, 'slds-show');
    $A.util.removeClass(lookupIconSearch, 'slds-hide');

    $A.util.addClass(pillTarget, 'slds-hide');
    $A.util.removeClass(pillTarget, 'slds-show');

    $A.util.addClass(lookUpTarget, 'slds-show');
    $A.util.removeClass(lookUpTarget, 'slds-hide');

    component.set("v.SearchKeyWord",null);
    component.set("v.listOfSearchRecords", null );
    component.set("v.selectedRecord", new Array() );   
  },

  // This function call when the end User Select any record from the result list.   
  handleComponentEvent : function(component, event, helper) {
  
    var isMultiEntry = component.get("v.multiEntry");

    // get the selected Account record from the COMPONETN event   
    var selectedAccountGetFromEvent = event.getParam("recordByEvent");
    var selectedItems = new Array();

    var lookupIconSearch = component.find("lookupIconSearch");
    $A.util.addClass(lookupIconSearch, 'slds-hide');
    $A.util.removeClass(lookupIconSearch, 'slds-show');

    var forclose = component.find("lookup-pill");
    $A.util.addClass(forclose, 'slds-show');
    $A.util.removeClass(forclose, 'slds-hide');

    var forclose = component.find("searchRes");
    $A.util.addClass(forclose, 'slds-is-close');
    $A.util.removeClass(forclose, 'slds-is-open');

    if (isMultiEntry) {
      var selectedRecord = component.get("v.selectedRecord");

      if(selectedRecord.length) {
        selectedItems = component.get("v.selectedRecord");
      }

      selectedItems.push(JSON.parse(JSON.stringify(selectedAccountGetFromEvent)));

      component.set("v.selectedRecord" , selectedItems); 
      component.set('v.SearchKeyWord',"");

    }else{

      component.set("v.selectedRecord" , selectedAccountGetFromEvent); 

      var lookUpTarget = component.find("lookupField");
      $A.util.addClass(lookUpTarget, 'slds-hide');
      $A.util.removeClass(lookUpTarget, 'slds-show');
    }

  }, 
  
  handleRemovePill: function (cmp, event) {
    var items = cmp.get('v.selectedRecord');
    var index = event.getSource().get("v.name");
    
      if(items.length == 1) {
      items = new Array();
    }else{
      items.splice(index, 1);      
    }

    cmp.set('v.selectedRecord', items);       
  },

  handleFillPill : function(component, event, helper) {

    var isMultiEntry  = component.get("v.multiEntry");
    var selectedRecord  = component.get("v.selectedRecord");
    var pillTarget    = component.find("lookup-pill");
    var lookUpTarget  = component.find("lookupField");
    var lookupIconSearch = component.find("lookupIconSearch");
    var forclose = component.find("searchRes");

    $A.util.addClass(lookupIconSearch, 'slds-hide');
    $A.util.removeClass(lookupIconSearch, 'slds-show');

    $A.util.addClass(pillTarget, 'slds-show');
    $A.util.removeClass(pillTarget, 'slds-hide');

    $A.util.addClass(forclose, 'slds-is-close');
    $A.util.removeClass(forclose, 'slds-is-open');
 
    if(!isMultiEntry) {
      $A.util.addClass(lookUpTarget, 'slds-hide');
      $A.util.removeClass(lookUpTarget, 'slds-show');
    }

    if(selectedRecord.length == 0) {
      $A.util.addClass(pillTarget, 'slds-hide');
      $A.util.removeClass(pillTarget, 'slds-show');

      $A.util.addClass(lookUpTarget, 'slds-show');
      $A.util.removeClass(lookUpTarget, 'slds-hide');

      component.set("v.selectedRecord", new Array() );
    }else{
        var prop1 = component.get("v.columnNameSearchMatch");
        var prop2 = component.get("v.columnNameRemoveMatch");
        
        selectedRecord.forEach(function(v, i) {
            if(v[prop1] == null && v[prop1] == null) {
                $A.util.addClass(pillTarget, 'slds-hide');
                $A.util.removeClass(pillTarget, 'slds-show');
                
                $A.util.addClass(lookUpTarget, 'slds-show');
                $A.util.removeClass(lookUpTarget, 'slds-hide');
                
                component.set("v.selectedRecord", new Array() );
            }
        });
    }
  },

  doValidation: function(component,event,helper) {
    return helper.doValidation(component,event);
  }
})