({
	processBarcode : function(component){
        
        console.log('-- processBarcode');
        
        component.set('v.duplicateColisNumber', null);
        var action = component.get("c.processBarcode");
        action.setParams({
            barcodeString : component.get('v.barcodeString'), 
            colisQuantity : component.get('v.colisQuantity'), 
            receptionDate : component.get('v.receptionDate'), 
            senderName : component.get('v.senderName'),
            newStatus : component.get('v.newStatus'), 
            newSousStatus : component.get('v.newSousStatus'), 
            newOwnerId : component.get('v.newOwnerId')
        });
        
        action.setCallback(this, function(response){
            if (response.getState() === "SUCCESS") {
                var result = response.getReturnValue();
                
                console.log('-- result ' + result);
                
                if(result){
                    component.set('v.duplicateColisNumber', result);
                    console.log('-- result ' + component.get('v.duplicateColisNumber'));
                } else {
                    console.log('ERROR!!');
                }
                component.set('v.showSpinner', false);
            }
        });
        $A.enqueueAction(action);
    }
})