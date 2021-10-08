({
    doInit : function(component, event, helper) {
        
        var action = component.get("c.createPicklist");
        action.setParams({
            recordTypeId: component.get("v.recordTypeId")
        });
        action.setCallback(this, function(response) {
            if(response.getState() === "SUCCESS"){
                if(response.getReturnValue() != null){
                    var res = response.getReturnValue();
                    component.set("v.objects", res);
                    component.set("v.selectedValue", res[0]);
                }
            }
        });
        $A.enqueueAction(action);	
    }
})