({
	doInit : function(component, event, helper) {

        console.log('--- here doInit');
        helper.processBarcode(component);
        console.log('--- here endInit');
    }
})