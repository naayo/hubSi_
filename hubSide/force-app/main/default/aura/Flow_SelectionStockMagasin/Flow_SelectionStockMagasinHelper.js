({
    retrieveAvailableStock : function(component){
        
        console.log('-- returnOneStock');
        console.log('-- productId ' + component.get('v.productId'));
        console.log('-- dateRetrait ' + component.get('v.dateRetrait'));
        console.log('-- dureeLocation ' + component.get('v.dureeLocation'));
        console.log('-- distributeurId ' + component.get('v.distributeurId'));
        
        component.set('v.selectedId', null);
        var action = component.get("c.returnOneStock");
        action.setParams({
            productId : component.get('v.productId'), 
            dateRetrait : component.get('v.dateRetrait'), 
            dureeLocation : component.get('v.dureeLocation'), 
            distributeurId : component.get('v.distributeurId'),
            isEmprunt : component.get('v.isEmprunt')
        });
        
        action.setCallback(this, function(response){
            if (response.getState() === "SUCCESS") {
                var result = response.getReturnValue();
                
                console.log('-- result ' + result);
                
                if(result){
                    component.set('v.selectedId', result);
                } else {
                    console.log('NO STOCK FOUND!!');
                    component.set('v.stockMsg', 'Le produit que vous avez demandé n\'a pas de stock dans votre magasin. Merci de séléctionner un autre produit ou de faire une réservation dans un autre magasin.');
                }
                component.set('v.showSpinner', false);
            }
        });
        $A.enqueueAction(action);
    }
})