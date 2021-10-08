/***
* @author Ariane Tanguy (GFI)
* @date 20/10/2020
* @description ContentDocumentLink Trigger
*/

trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
    
    // AFTER TRIGGERS
    if(Trigger.isAfter){
        
        // AFTER INSERT TRIGGERS
        if(Trigger.isInsert){
            
            system.debug('-- AFTER CD INSERT');
            
            // Get the related ContentVersion
            List<ContentVersion> contentVersionList = ContentDocumentLinkTriggerHelper.getRelatedCDVersion(Trigger.new);
            ContentDocumentLinkTriggerHandler.createContentDistribution(contentVersionList);
        }
    }
}