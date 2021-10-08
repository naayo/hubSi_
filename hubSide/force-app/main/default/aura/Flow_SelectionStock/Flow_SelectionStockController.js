({
    doInit : function(component, event, helper) {

        console.log('--- here doInit');
        helper.retrieveAvailableStock(component);
        helper.getAllDistributeur(component);
        console.log('--- here endInit');
    }, 
    
    selectThis : function(component, event, helper){
        var id = event.currentTarget.getAttribute('id');
        console.log('attribute Id:', id);
        helper.selectDistributeur(component, id);
    }
})