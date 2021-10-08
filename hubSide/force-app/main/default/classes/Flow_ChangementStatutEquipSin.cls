/***
* @author Ariane Tanguy (GFI)
* @date 28/04/2021
* @description Lightning Component Controller
*/

public class Flow_ChangementStatutEquipSin {
    
    // Input details that comes to apex from flow
    public class FlowInputs{
        
        @InvocableVariable
        public String barcodeString;
        
        @InvocableVariable
        public String newStatus;
        
        @InvocableVariable
        public String newSubStatus;
        
        @InvocableVariable
        public String selectedRT;
        
        @InvocableVariable
        public Boolean getCurrentStatus = false;
        
        @InvocableVariable
        public Boolean setFinalStatus = false;
    }
    
    // Output details which goes from apex to flow
    public class FlowOutputs{
        
        @InvocableVariable
        public Integer barcodeCount;
        
        @InvocableVariable
        public String currentStatusString;
        
        @InvocableVariable
        public Boolean isErrorRT;
    }
    
    @InvocableMethod(label = 'Update EquipSin status' 
                     description = 'Either returns the current status or update the status/sub status.')
    
    public static List<FlowOutputs> updateEquipSinStatus(List<FlowInputs> requestList) {
        
        List<FlowOutputs> resultList = new List<FlowOutputs>();
        
        for(FlowInputs f : requestList){
            
            FlowOutputs r = new FlowOutputs();
            
            List<Equipement_Sinistre__c> equipSinList = [SELECT id, Statut_equipement__c, Sous_statut__c, Numero_sinistre__c
                                                         FROM Equipement_Sinistre__c
                                                         WHERE Numero_sinistre__c IN: splitBarcode(f.barcodeString)
                                                         AND RecordTypeId =: f.selectedRT];
            system.debug('-- equipSinList ' + equipSinList);
            Boolean isRTEchange = [SELECT DeveloperName FROM RecordType WHERE id =: f.selectedRT].DeveloperName.contains('perdu');
            
            r.barcodeCount = equipSinList.size();
            
            // Get the current status
            if(f.getCurrentStatus && !f.setFinalStatus){
                
                system.debug('-- Get current status ');
                
                // Loop over the retrieved records
                Map<String, Integer> statusCountMap = new Map<String, Integer>();
                for(Equipement_Sinistre__c e : equipSinList){
                    String s = e.Statut_equipement__c;
                    if(e.Sous_statut__c != NULL){
                        s += ' ' + e.Sous_statut__c;
                    }
                    
                    if(!statusCountMap.keySet().contains(s)){
                        statusCountMap.put(s, 0);
                    }
                    statusCountMap.put(s, statusCountMap.get(s) + 1);
                }
                
                String finalString = 'Pas de statut mappé';
                if(statusCountMap.keySet().size() > 0){
                    
                    // Loop over the mapped result
                    finalString = 'Vous avez scanné ' + '\n';
                    for(String s : statusCountMap.keySet()){
                        finalString += statusCountMap.get(s) + ' équipement(s) de statut ' + s + '\n';
                    }
                }
                system.debug('-- finalString ' + finalString);
                r.currentStatusString = finalString;
                resultList.add(r);
                continue;
            }
            
            // Simply update the equipSin with the status
            if(!f.getCurrentStatus && !f.setFinalStatus){
                system.debug('-- update status ');
                
                // Loop over the retrieved records
                for(Equipement_Sinistre__c e : equipSinList){
                    if(f.newStatus != NULL){
                        e.Statut_equipement__c = f.newStatus;
                        e.Sous_statut__c = f.newSubStatus;
                    }
                }
                try{
                    update equipSinList;
                    system.debug('-- equipSinList ' + equipSinList);
                    r.isErrorRT = false;
                }
                catch(Exception e){
                    r.isErrorRT = true;
                    system.debug('-- error : ' + e.getMessage());
                }
                resultList.add(r);
                continue;
            } 
            
            // Set the final status
            if(!f.getCurrentStatus && f.setFinalStatus){
                system.debug('-- final status ');
                
                // Get the related historique
                List<Name__c> relatedHistorique = [SELECT id, Name, Equipement_sinistre__c
                                                   FROM Name__c 
                                                   WHERE Equipement_sinistre__c =: equipSinList
                                                   ORDER BY CreatedDate DESC];
                system.debug('-- relatedHistorique ' + relatedHistorique);
                
                // Map the equipement to their related historique
                Map<id, List<Name__c>> relatedHistoriqueMap = new Map<id, List<Name__c>>();
                for(Name__c h : relatedHistorique){
                    if(!relatedHistoriqueMap.keySet().contains(h.Equipement_sinistre__c)){
                        List<Name__c> tmpList = new List<Name__c>();
                        relatedHistoriqueMap.put(h.Equipement_sinistre__c, tmpList);
                    }
                    relatedHistoriqueMap.get(h.Equipement_sinistre__c).add(h);
                }
                
                // Map the historique to the related equipSin
                Map<id, String> equipSinIdNewStatusMap = new Map<id, String>();
                Map<id, String> equipSinIdNewSStatusMap = new Map<id, String>();
                
                // Loop over the equipement sinistre
                for(id e : relatedHistoriqueMap.keySet()){
                    
                    // And over its related historique
                    for(Name__c h : relatedHistoriqueMap.get(e)){
                        
                        if(h.Name.contains('Irréparable - A retourner Retour Client')){
                            equipSinIdNewStatusMap.put(h.Equipement_sinistre__c, 'Irréparable');
                            equipSinIdNewSStatusMap.put(h.Equipement_sinistre__c, 'Réception client');
                            break;
                        }
                        if(h.Name.contains('Irréparable - A retourner Retour SFAM')){
                            equipSinIdNewStatusMap.put(h.Equipement_sinistre__c, 'Irréparable');
                            equipSinIdNewSStatusMap.put(h.Equipement_sinistre__c, 'Conservé SFAM');
                            break;
                        }
                        if(h.Name.contains('Annulé - A retourner Retour SFAM')){
                            equipSinIdNewStatusMap.put(h.Equipement_sinistre__c, 'Annulé');
                            equipSinIdNewSStatusMap.put(h.Equipement_sinistre__c, 'Conservé SFAM');
                            break;
                        }
                        if(h.Name.contains('Annulé - A retourner Retour Client')){
                            equipSinIdNewStatusMap.put(h.Equipement_sinistre__c, 'Annulé');
                            equipSinIdNewSStatusMap.put(h.Equipement_sinistre__c, 'Réception client');
                            break;
                        }
                        if(h.Name == 'Expédition client Préparation' && isRTEchange){
                               equipSinIdNewStatusMap.put(h.Equipement_sinistre__c, 'CustomerReception');
                               break;
                           }
                        if(h.Name == 'Expédition client Préparation' && !isRTEchange){
                            equipSinIdNewStatusMap.put(h.Equipement_sinistre__c, 'Réparé Réception client');
                            break;
                        }
                        if(h.Name.contains('Annulé - A retourner')){
                            equipSinIdNewStatusMap.put(h.Equipement_sinistre__c, 'Annulé');
                            break;
                        }
                        if(h.Name.contains('En Cours de Réparation')){
                            equipSinIdNewStatusMap.put(h.Equipement_sinistre__c, 'Réparé Réception client');
                            break;
                        }
                    }
                }
                system.debug('-- equipSinIdNewStatusMap ' + equipSinIdNewStatusMap);
                system.debug('-- equipSinIdNewSStatusMap ' + equipSinIdNewSStatusMap);
            
                r.barcodeCount = 0;
                
                // Loop over the equipSin
                for(Equipement_Sinistre__c e : equipSinList){
                    if(equipSinIdNewStatusMap.keySet().contains(e.id)){
                        e.Statut_equipement__c = equipSinIdNewStatusMap.get(e.id);
                        r.barcodeCount ++;
                    } else {
                        continue;
                    }
                    if(equipSinIdNewStatusMap.keySet().contains(e.id)){
                        e.Sous_statut__c = equipSinIdNewSStatusMap.get(e.id);
                    } else {
                        e.Sous_statut__c = NULL;
                    }
                }
                
                system.debug('-- equipSinList ' + equipSinList);
                update equipSinList;
                resultList.add(r);
            }
        }
        
        return resultList;
    }
    
    /***
    * @description Split barcode
    * @param barcode - List chronopost ids
    * @return List<String> - Barcode list
    */
    public static List<String> splitBarcode(String barcode) {
        
        // Split the barcodes
        List<String> barcodeList = new List<String>();
        if(barcode != NULL && barcode.contains('\r\n')){
            barcodeList = barcode.replace(' ', '').split('\r\n');
        }
        else if(barcode != NULL && barcode.contains('\n')){
            barcodeList = barcode.replace(' ', '').split('\n');
        }
        else if(barcode != NULL){
            barcodeList = barcode.replace(' ', '').split('\r\n');
        }
        
        return barcodeList;
    }
}