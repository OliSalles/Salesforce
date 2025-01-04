/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 07-10-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class MultiSelectLookupCtrl {
    
    @AuraEnabled(cacheable=true)
    public static List<sObject> retriveSearchData(String ObjectName, String fieldName, String value, List<String> selectedRecId, String recordTypeName, String condition ) {

        Id RecordTypeId;

        if( String.isNotBlank( recordTypeName ) )
            RecordTypeId = ((SObject)Type.forName('Schema', ObjectName).newInstance()).getSObjectType().getDescribe().getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();

        List<sObject> sObjectResultList = new List<sObject>();
       
        if( selectedRecId == null )
            selectedRecId = new List<String>(); 
        
        if( value != null && value != '' ) {

            String query = ''; 

            query = 'SELECT ' + fieldName + ' FROM ' + ObjectName;

            if( value != 'Last modified' ){ 

                query += ' WHERE ';
 
                if( String.isNotBlank( recordTypeName ) ){
                    query += ' RecordTypeId = \'' + RecordTypeId + '\' AND ';
                } 

                if( String.isNotBlank( condition ) ){
                    query += condition + ' AND ';
                }
                query += ' Name LIKE \'%' + value.trim() + '%\' AND ';
            
            }else if( String.isNotBlank( recordTypeName ) || String.isNotBlank( condition ) ){ 
                
                
                if( String.isNotBlank( recordTypeName ) ){
                    query += ' WHERE RecordTypeId = \'' + RecordTypeId + '\'';
                
                }else if( String.isNotBlank( condition ) ){
                    query += ' WHERE ' + condition;
                } 
                query += ' AND ';

            }else{
                query += ' WHERE ';
            }   

            String userId = UserInfo.getUserId();

            query += ' ID NOT IN: selectedRecId ';  
             
            if( ObjectName != 'User' ){
                query += ' AND OwnerId = \'' + userId + '\' ';
            }

            query += ' ORDER BY createdDate DESC LIMIT 10'; 

            System.debug('Query ===> ' + query); 

            for(sObject so : Database.Query(query)) {
                sObjectResultList.add(so);
            }
        }
        return sObjectResultList;
    }
}