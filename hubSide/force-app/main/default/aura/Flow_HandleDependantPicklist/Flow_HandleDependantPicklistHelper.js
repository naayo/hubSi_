({
    getPicklistValues: function(component, event) {
        
        console.log('-- getUserBusinessProfile');
        
        var action = component.get("c.getUserBusinessProfile");        
        action.setCallback(this, function(response){
            if (response.getState() === "SUCCESS") {
                var result = response.getReturnValue();
                component.set('v.businessProfile', result);
            }
            
            var action = component.get("c.getControllingPicklistFiltered");
            action.setParams({
                objectName : component.get('v.objectName'), 
                controllingField : component.get('v.controllingPkName'), 
                businessProfile : component.get('v.businessProfile'), 
                RTName : component.get('v.RTName')
            });
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    var controllingPk = [];
                    for(var key in result){
                        controllingPk.push({key: key, value: result[key]});
                    }
                    component.set("v.controllingPk", controllingPk);
                }
            });
            $A.enqueueAction(action);
            
        });
        $A.enqueueAction(action);
    }, 
    
    handlePicklistChange: function(component, event) {
        
        console.log('-- handlePicklistChange');
        
        if(component.get('v.dependantPkName')){
            
            var action = component.get("c.getDependantPicklistFiltered");
            action.setParams({
                objectName : component.get('v.objectName'), 
                controllingField : component.get('v.controllingPkName'), 
                dependantField : component.get('v.dependantPkName'),
                controllingChoice : component.get('v.controllingPkValue'),
                businessProfile : component.get('v.businessProfile')
            });
            
            action.setCallback(this, function(response) {
                var state = response.getState();
                
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    component.set("v.displayDependantPk", false);
                    
                    var dependantPk = [];
                    for(var key in result){
                        dependantPk.push({key: key, value: result[key]});
                        component.set("v.displayDependantPk", true);
                    }
                    component.set("v.dependantPk", dependantPk);
                }
            });
            $A.enqueueAction(action);
        }
    }
})