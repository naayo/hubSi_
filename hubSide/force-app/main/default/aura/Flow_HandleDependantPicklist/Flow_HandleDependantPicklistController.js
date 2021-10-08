({
    doInit: function(component, event, helper) {
        helper.getPicklistValues(component, event);
    },
    
    handleOnChange : function(component, event, helper) {
        helper.handlePicklistChange(component, event);
    }
})