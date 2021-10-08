/***
* @author Ariane Tanguy (GFI)
* @date 02/11/2020
* @description Lightning Component Controller
*/

public class Flow_BarcodeScanInvokable {
    
    // Input details that comes to apex from flow
    public class FlowInputs{
        
        @InvocableVariable
        public String barcodeString;
        
        @InvocableVariable
        public List<String> objectIdList;
        
        @InvocableVariable
        public String objectToQuery;
        
        @InvocableVariable
        public String fieldToQuery;
        
        @InvocableVariable
        public String fieldToUpdate;
        
        @InvocableVariable
        public String valueToUpdate;
    }
    
    // Output details which goes from apex to flow
    public class FlowOutputs{
        
        @InvocableVariable
        public Integer barcodeCount;
        
        @InvocableVariable
        public List<String> barcodeList;
        
        @InvocableVariable
        public List<String> currentValueList;

        @InvocableVariable
        public List<String> barcodeError;

        @InvocableVariable
        public Integer barcodeErrorCount;

        @InvocableVariable
        public List<String> barcodeValid;
    }
    
    @InvocableMethod(label = 'Split Barcode' 
                     description = 'Split flow string into workable barcode strings.')
    
    public static List<FlowOutputs> splitBarcode(List<FlowInputs> requestList) {
        
        List<FlowOutputs> resultList = new List<FlowOutputs>();
        List<sObject> sObjectToUpdate = new List<sObject>();
        List<String> barcodeValid = new List<String>();
        List<String> barcodeError = new List<String>();
        
        for(FlowInputs f : requestList){
            
            FlowOutputs r = new FlowOutputs();
            
            // If there is something to query
            if(f.objectToQuery != NULL && f.fieldToUpdate != NULL &&
               f.fieldToQuery != NULL && f.valueToUpdate != NULL && 
               (f.barcodeString != NULL ||
                f.objectIdList != NULL)){
                    
                   String sQ = '(';
                   if(f.barcodeString != NULL){
                       for(String s : splitBarcode(f.barcodeString)){
                           sQ += ('\'' + s + '\', ');
                       }
                   } else if(f.objectIdList != NULL){
                       for(String s : f.objectIdList){
                           sQ += ('\'' + s + '\', ');
                       }
                   }
                   sQ = sQ.Substring(0, sQ.length()-2) + ')';
                   
                   Database.QueryLocator q = Database.getQueryLocator('SELECT id, ' + f.fieldToUpdate + ',' + f.fieldToQuery +
                                                                      ' FROM ' + f.objectToQuery + 
                                                                      ' WHERE ' + f.fieldToQuery + 
                                                                      ' IN ' + sQ);
                   Database.QueryLocatorIterator it = q.iterator();
                   List<sObject> sObjectList = new List<sObject>();
                   while (it.hasNext()){
                       sObjectList.add((sObject)it.next());
                   }
                   system.debug('-- sObjectList ' + sObjectList);
                   
                   // Loop over the retrieved records
                   for(sObject o : sObjectList){
                    
                       if (f.objectToQuery == 'Colis__c' && f.fieldToUpdate == 'Statut__c' && (String)o.get(f.fieldToUpdate) != 'Retourner Colis' && f.valueToUpdate == 'Colis Retourné') {
                           barcodeError.add((String)o.get(f.fieldToQuery));
                       } else {
                           Map <String, Schema.SObjectField> fieldMap = o.getSobjectType().getDescribe().fields.getMap();
                           system.debug('-- o ' + o);                       
                           if(fieldMap.containsKey(f.fieldToUpdate)){
                                o.put(f.fieldToUpdate, f.valueToUpdate);
                                sObjectToUpdate.add(o);
                                system.debug('-- updated o ' + o);
                                barcodeValid.add((String)o.get(f.fieldToQuery));
                       }
                       
                   }
               }
            }
            
            r.barcodeCount = barcodeValid.size();
            r.barcodeList = splitBarcode(f.barcodeString); 
            r.barcodeError = barcodeError;
            r.barcodeErrorCount = barcodeError.size();
            resultList.add(r);
        }
        
        update sObjectToUpdate;
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
        if(barcode != NULL && barcode.contains('\n')){
            barcodeList = barcode.replace(' ', '').split('\n');
        }
        else if(barcode != NULL && barcode.contains('\r\n')){
            barcodeList = barcode.replace(' ', '').split('\r\n');
        }
        else if(barcode != NULL){
            barcodeList = barcode.replace(' ', '').split('\r\n');
        }
        
        return barcodeList;
    }
}