({
    doInit : function(component, event, helper) {

        console.log('--- here doInit');
        helper.retrieveAvailableStock(component);
        console.log('--- here endInit');
    }
})