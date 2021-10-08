/***
* @author Ariane Tanguy (GFI)
* @date 02/11/2020
* @description Lightning Component Controller
*/

public class Flow_CreateUpdateColisInvokable {
    
    // Input details that comes to apex from flow
    public class FlowInputs{
        
        @InvocableVariable
        public String barcodeString;
        
        @InvocableVariable
        public Integer colisQuantity;
        
        @InvocableVariable
        public String receptionColisId;
        
        @InvocableVariable
        public Date receptionDate;
        
        @InvocableVariable
        public String senderName;
        
        @InvocableVariable
        public Boolean createColis;
    }
    
    // Output details which goes from apex to flow
    public class FlowOutputs{
        
        @InvocableVariable
        public Integer barcodeCount;
        
        @InvocableVariable
        public Integer barcodeProcessed;
    }
    
    /***
    * @description Create n colis + m other colis
    * @param barcodeString - List ids
    * @param colisQuantity - Number of other colis to create
    * @param receptionDate - reception date
    * @param newStats - new status
    * @return Integer - Number of colis created
    */
    @InvocableMethod(label = 'Create / Update colis' 
                     description = 'Split flow string and create / update colis accordingly.')
    
    public static List<FlowOutputs> processBarcode(List<FlowInputs> requestList) {
        
        List<FlowOutputs> resultList = new List<FlowOutputs>();
        List<Colis__c> colisToUpsert = new List<Colis__c>();
        
        for(FlowInputs f : requestList){
            
            FlowOutputs r = new FlowOutputs();
            
            // Split the barcodes
            List<String> barcodeList = new List<String>();
            if(f.barcodeString != NULL && f.barcodeString.contains('\n')){
                barcodeList = f.barcodeString.replace(' ', '').split('\n');
            }
            else if(f.barcodeString != NULL && f.barcodeString.contains('\r\n')){
                barcodeList = f.barcodeString.replace(' ', '').split('\r\n');
            }
            else if(f.barcodeString != NULL){
                barcodeList = f.barcodeString.replace(' ', '').split('\r\n');
            }
            
            // Check for duplicates
            Set<String> barcodeSet = new Set<String>();
            for(String b : barcodeList){
                barcodeSet.add(b);
            }
            
            r.barcodeProcessed = barcodeSet.size();
            r.barcodeCount = barcodeList.size();
            resultList.add(r);
            
            // Create colis
            if(f.CreateColis){
                createColis(barcodeSet, f.colisQuantity, f.receptionDate, f.senderName, f.receptionColisId);
            }
        }
        
        return resultList;
    }
    
    /***
    * @description Create n colis + m other colis
    * @param barcodeString - List ids
    * @param colisQuantity - Number of other colis to create
    * @param receptionDate - reception date
    * @return Integer - Number of colis created
    */
    private static void createColis(Set<String> barcodeSet, integer colisQuantity, date receptionDate, string senderName, string RCId){
        
        id receivedColisRT = UtilityClassHelper.getCreatedRecordType('Colis_reception');
        List<Colis__c> colisToInsert = new List<Colis__c>();
        
 		if(senderName.contains('Chronopost') || senderName.contains('LaPoste')){
            // Loop over the barcodes
            for(String barcode : barcodeSet) {
                Colis__c c = new Colis__c();
                c.Name = barcode;
                c.Date_reception__c = receptionDate;
                c.Nom_transporteur__c = senderName;
                c.Reception_colis__c = RCId;
                c.RecordTypeId = receivedColisRT;
                c.Statut__c = 'Reçu';
                colisToInsert.add(c);
            }
        }
        
        if(senderName.contains('BulkParcels')) {
            // and over the colis to create
            for(integer i = 0; i<colisQuantity; i++){
                Colis__c c = new Colis__c();
                c.Name = receptionDate + senderName + i;
                c.Date_reception__c = receptionDate;
                c.Nom_transporteur__c = senderName;
                c.Reception_colis__c = RCId;
                c.RecordTypeId = receivedColisRT;
                c.Statut__c = 'Reçu';
                colisToInsert.add(c);
            }
        }
        
        insert colisToInsert;
    }
}