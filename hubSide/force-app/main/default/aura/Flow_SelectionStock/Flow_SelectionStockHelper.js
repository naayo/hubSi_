({
    retrieveAvailableStock : function(component){
        
        console.log('-- retrieveAvalaibleStock');
        
        component.set('v.availableStockIdList', null);
        var action = component.get("c.retrieveStock");
        action.setParams({
            productId : component.get('v.productId'), 
            dateRetrait : component.get('v.dateRetrait'), 
            dureeLocation : component.get('v.dureeLocation'), 
            enseigne : component.get('v.enseigne'), 
            livraisonDomicile : component.get('v.livraisonDomicile'), 
            getStock : component.get('v.showSpinner')
        });
        
        action.setCallback(this, function(response){
            if (response.getState() === "SUCCESS") {
                var result = response.getReturnValue();
                
                console.log('-- result ' + result);
                
                if(result){
                    component.set('v.availableStockIdList', result);
                    console.log('-- result ' + component.get('v.availableStockIdList'));
                    console.log('-- showSpinner ' + component.get('v.showSpinner'));
                } else {
                    console.log('NO STOCK FOUND!!');
                    component.set('v.stockMsg', 'Pas de stock disponible aux dates demandées.');
                    component.set('v.showSpinner', false);
                    component.set('v.resultOk', false);
                    console.log('NOK');
                }
            }
        });
        $A.enqueueAction(action);
    }, 
    
    getAllDistributeur : function(component){
        
        console.log('-- getAllDistributeur');
        
        component.set('v.distributeurList', null);
        var action = component.get("c.getAllDistributeur");
        
        action.setParams({
            productId : component.get('v.productId'), 
            dateRetrait : component.get('v.dateRetrait'), 
            dureeLocation : component.get('v.dureeLocation'), 
            enseigne : component.get('v.enseigne'), 
            livraisonDomicile : component.get('v.livraisonDomicile')
        });
        
        action.setCallback(this, function(response){
            if (response.getState() === "SUCCESS") {
                var result =  response.getReturnValue();
                if(result){
                    component.set('v.distributeurList', result);
                    console.log('-- distributeurList ' + component.get('v.distributeurList'));
                } else {
                    console.log('NO STOCK FOUND!!');
                }
            }
        });
        $A.enqueueAction(action);
        
        component.set('v.showSpinner', false);
        component.set("v.openDistribChoice", true);
    },
    
    selectDistributeur : function(component, selectedId){
        
        console.log('-- selectDistributeur');
        
        var options = component.get("v.distributeurList");
        options.forEach( function (option){
            var el =  document.getElementById(option.id);
            el.classList.remove('xcs-selected');
            
            if(option.id == selectedId){
                if(option.selected){
                    //if this option was previously selected then deselect it
                    option.selected = false;
                }
                else{
                    option.selected = true;
                    var el =  document.getElementById(selectedId);
                    el.className = 'xcs-selected thumbnail';
                }
            }
            else option.selected = false;            
            component.set("v.distributeurId", selectedId);
            component.set("v.openModal", true);
        });	
        
        console.log('selectedId:',component.get('v.distributeurId'));
        
        component.set('v.selectedId', null);
        var action = component.get("c.returnOneStockFromList");
        action.setParams({
            stockIdList : component.get('v.availableStockIdList'),
            distributeurId : component.get('v.distributeurId')
        });
        
        action.setCallback(this, function(response){
            if (response.getState() === "SUCCESS") {
                var result =  response.getReturnValue();
                if(result){
                    component.set('v.selectedId', result);
                    component.set('v.resultOk', true);
                    console.log('OK');
                } else {
                    console.log('NO STOCK FOUND!!');
                }
            }
        });
        $A.enqueueAction(action);
    }
})