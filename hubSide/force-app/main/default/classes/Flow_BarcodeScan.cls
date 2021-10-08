/***
* @author Ariane Tanguy (GFI)
* @date 02/11/2020
* @description Lightning Component Controller
*/

public with sharing class Flow_BarcodeScan {
    
    /***
    * @description Create n chronopost colis + m other colis
    * @param barcodeString - List chronopost ids
    * @param colisQuantity - Number of other colis to create
    * @param receptionDate - reception date
    * @param newStats - new status
    * @return Integer - Number of chronopost colis created
    */
    @AuraEnabled
    public static integer processBarcode(String barcodeString, 
                                         integer colisQuantity, 
                                         date receptionDate, 
                                         string senderName, 
                                         string newStatus, 
                                         string newSousStatus,
                                         String newOwnerId){
        
        // Split the barcodes
        List<String> barcodeList = new List<String>();
        if(barcodeString != NULL){
         	barcodeList = barcodeString.split('\r\n');
        }

        // Check for duplicates
        Set<String> barcodeSet = new Set<String>();
		for(String b : barcodeList){
            barcodeSet.add(b);
        }
        
        // Check whether we need to create colis or to change status
        Integer numberObjectCreated = barcodeSet.size();
        if(!(newStatus == NULL ||
             newStatus == '')){
                 numberObjectCreated = updateStatus(barcodeSet, newStatus, newSousStatus);
             }
        if(!(newOwnerId == NULL ||
             newOwnerId == '')){
               numberObjectCreated = updateOwner(barcodeSet, newOwnerId);
           }
		createColis(barcodeSet, colisQuantity, receptionDate, senderName);

        return barcodeList.size() - numberObjectCreated;
    }
    
    /***
    * @description Create n chronopost colis + m other colis
    * @param barcodeString - List chronopost ids
    * @param colisQuantity - Number of other colis to create
    * @param receptionDate - reception date
    * @return Integer - Number of chronopost colis created
    */
    private static void createColis(Set<String> barcodeSet, integer colisQuantity, date receptionDate, string senderName){
        
        id receivedColisRT = UtilityClassHelper.getCreatedRecordType('Colis_reception');
        List<Colis__c> colisToInsert = new List<Colis__c>();
        
        // Loop over the barcodes
        for(String barcode : barcodeSet){
            Colis__c c = new Colis__c();
            c.Name = barcode;
            c.Date_reception__c = receptionDate;
            c.Nom_transporteur__c = senderName;
            c.RecordTypeId = receivedColisRT;
            colisToInsert.add(c);
        }
        
        // and over the colis to create
        for(integer i = 0; i<colisQuantity; i++){
            Colis__c c = new Colis__c();
            c.Name = receptionDate + senderName + i;
            c.Date_reception__c = receptionDate;
            c.Nom_transporteur__c = senderName;
            c.RecordTypeId = receivedColisRT;
            colisToInsert.add(c);
        }
        
        insert colisToInsert;
    }
    
    /***
    * @description Update n status
    * @param barcodeString - List chronopost ids
    * @param newStatus - new status
    * @return Integer - Number of object updated
    */
    private static integer updateStatus(Set<String> barcodeSet, string newStatus, string newSousStatus){
        
        // Query the Equipement Sinistre
        List<Equipement_sinistre__c> equipmentSinistreList = [SELECT id, Statut_equipement__c, Sous_statut__c
                                                              FROM Equipement_sinistre__c
                                                              WHERE Sinistre__r.Numero_sinistre__c IN: barcodeSet];
        
        // And change their status
        for(Equipement_sinistre__c e : equipmentSinistreList){
            e.Statut_equipement__c = newStatus;
            if(newSousStatus != NULL){
                e.Sous_statut__c = newSousStatus;
            }
        }
        
        update equipmentSinistreList;        
        return equipmentSinistreList.size();
    }
    
    /***
    * @description Update n status
    * @param barcodeString - List chronopost ids
    * @param newOwnerId - new owner id
    * @return Integer - Number of object updated
    */
    private static integer updateOwner(Set<String> barcodeSet, String newOwnerId){
        
        // Query the Equipement Sinistre
        List<Colis__c> colisList = [SELECT id, ownerId
                                    FROM Colis__c
                                    WHERE Name IN: barcodeSet];
        
        // And change their status
        for(Colis__c c : colisList){
            c.ownerId = newOwnerId;
            c.Statut__c = 'Affecté';
        }
        update colisList;        
        return colisList.size();
    }
}