/***
* @author Ariane Tanguy (GFI)
* @date 07/04/2021
* @description Lightning Component Controller
*/

public with sharing class Flow_HandleDependantPicklist {

    /***
    * @description Get the current user business profile
    * @return String - business profile
    */
    @AuraEnabled(cacheable = true)
    public static String getUserBusinessProfile() {
        
        User u = [SELECT id, businessProfile__c 
                  FROM User 
                  WHERE id =: system.UserInfo.getUserId()];
        
        system.assert(u.BusinessProfile__c != NULL, 
                     'Your user doesn\'t have any business profile - Please check.');
        
        return u.businessProfile__c;
    }
    
    /***
    * @description Get the SFAM Config values
    * @param String objectName 
    * @param String field 
    * @param String businessProfile / RT name
    * @return List<String> - Field preselected values
    */
    public static List<String> getSFAMPicklist(String objectName, String field, String SFAMConfigName) {
                
        // Find out the SFAMConfig field name
        String SFAMConfigFieldName =  objectName.split('__c')[0] + '_' + field;
        
        // Get the related SFAMConfig
        Database.QueryLocator q = Database.getQueryLocator('SELECT id, ' + 
                                                           SFAMConfigFieldName + ' ' + 
                                                           'FROM SFAMConfig__c ' + 
                                                           'WHERE UserBusinessProfile__c = \'' + 
                                                           SFAMConfigName + '\' ' +
                                                           'OR Name = \'' + 
                                                           SFAMConfigName + '\'');
        Database.QueryLocatorIterator it = q.iterator();
        List<SFAMConfig__c> SFAMConfigList = new List<SFAMConfig__c>();
        while (it.hasNext()){
            SFAMConfigList.add((SFAMConfig__c)it.next());
        }
        
        // Return null if empty
        if(SFAMConfigList.size() == 0){
            return new List<String>();
        }
        
        system.assert(SFAMConfigList.size() == 1, 
                      'There are more than one picklist configured for this business profile / RT - Please check. \n ' + 
                      SFAMConfigList);
        
        // Get the SFAMConfig field related value
        Map<String, Schema.SObjectField> object_fields_map = Schema.getGlobalDescribe().get('SFAMConfig__c').getDescribe().fields.getMap();        
        Schema.sObjectField objField = object_fields_map.get(SFAMConfigFieldName);
        
        // Return null if empty
        if(String.valueOf(SFAMConfigList[0].get(objField)) == NULL){
            return new List<String>();
        }
        
        return String.valueOf(SFAMConfigList[0].get(objField)).split(';');
    }

    /***
    * @description Get the filtered controlling picklist map
    * @param String objectName 
    * @param String controllingField 
    * @param String businessProfile 
    * @return Map<String, String> - picklist label mapped to picklist values
    */
    @AuraEnabled(cacheable = true)
    public static Map<String, String> getControllingPicklistFiltered(String objectName, 
                                                                     String controllingField, 
                                                                     String businessProfile, 
                                                                     String RTName) {
                                                                         
        // Get the picklist label + values
        Map<String, String> controllingPkMap = UtilityClassHelper.getPicklistValues(objectName, controllingField);
                                                                         
        // Handle the business profile scenario
        Map<String, String> businessProfileControllingPkMap = new Map<String, String>();
        if(businessProfile != NULL){
            
            // Get the SFAM Config preselected choices
            List<String> controllingPkFilteredValueList = getSFAMPicklist(objectName, controllingField, businessProfile);
            
            // Handle the not configured case
            if(controllingPkFilteredValueList.size() == 0){
                if(RTName == NULL){
                    return controllingPkMap;
                } else {
                    controllingPkFilteredValueList = new List<String>(controllingPkMap.values());
                }
            }
            
            // Filter the map with the business profile
            for(String s : controllingPkMap.keySet()){
                if(controllingPkFilteredValueList.contains(controllingPkMap.get(s))){
                    businessProfileControllingPkMap.put(s, controllingPkMap.get(s));
                }
            }
        }
        
        // Handle the RT scenario
        Map<String, String> RTControllingPkMap = new Map<String, String>();
        if(RTName != NULL){
            
            // Get the SFAM Config preselected choices
            List<String> controllingPkFilteredValueList = getSFAMPicklist(objectName, controllingField, RTName);
            
            // Handle the not configured case
            if(controllingPkFilteredValueList.size() == 0){
                if(businessProfileControllingPkMap.keySet().size() > 0){
                    return businessProfileControllingPkMap;
                } else {
                    return controllingPkMap;
                }
            }
            
            // Filter the map with the business profile        
            for(String s : controllingPkMap.keySet()){
                if(controllingPkFilteredValueList.contains(controllingPkMap.get(s))){
                    RTControllingPkMap.put(s, controllingPkMap.get(s));
                }
            }
        } else {
            return businessProfileControllingPkMap;
        }
        
        // Check whether both info were given - if so, filter the picklist values again
        Map<String, String> filteredControllingPkMap = new Map<String, String>();
        if(RTControllingPkMap.keySet().size() > 0 && businessProfileControllingPkMap.size() > 0){
            for(String s : RTControllingPkMap.keySet()){
                if(businessProfileControllingPkMap.keySet().contains(s)){
                    filteredControllingPkMap.put(s, RTControllingPkMap.get(s));
                }
            }
        }
        return filteredControllingPkMap;
    }
    
    /***
    * @description Get the dependant picklist map
    * @param String objectName 
    * @param String controllingField 
    * @param String dependantField 
    * @param String controllingChoice 
    * @return Map<String, String> - picklist label mapped to picklist values
    */
    @AuraEnabled(cacheable = true)
    public static Map<String, String> getDependantPicklistFiltered(String objectName, String controllingField, String dependantField, String controllingChoice, String businessProfile) {

        // Get the corresponding controntrolling picklist value
        Map<String, String> controllingPkMap = UtilityClassHelper.getPicklistValues(objectName, controllingField);
        for(String s : controllingPkMap.keySet()){
            if(controllingPkMap.get(s) == controllingChoice){
                controllingChoice = s;
                break;
            }
        }
        
        // Get the dependant picklist label + values
        Map<String, String> dependantPkMap = UtilityClassHelper.getPicklistValues(objectName, dependantField);
        
        // Get the SFAM Config preselected choices
        List<String> dependantPkFilteredValueList = getSFAMPicklist(objectName, dependantField, businessProfile);
        
        // Handle the not configured case
        Map<String, String> dependantPkMapFiltered = new Map<String, String>();
        if(dependantPkFilteredValueList.size() == 0){
            dependantPkMapFiltered = dependantPkMap;
        } else {
            for(String s : dependantPkMap.keySet()){
                if(dependantPkFilteredValueList.contains(dependantPkMap.get(s))){
                    dependantPkMapFiltered.put(s, dependantPkMap.get(s));
                }
            }
        }
        
        // Get the dependancy picklist info
        Map<String, List<String>> dependancyMap = UtilityClassHelper.getDependentPicklistValues(objectName, controllingField, dependantField);
        
        // Filter the dependancy info
        Map<String, String> filteredDependantPkMap = new Map<String, String>();
        for(String s : dependancyMap.get(controllingChoice)){
            if(dependantPkMapFiltered.keySet().contains(s)){
                filteredDependantPkMap.put(s, dependantPkMapFiltered.get(s));
            }
        }
        
        return filteredDependantPkMap;
    }
}