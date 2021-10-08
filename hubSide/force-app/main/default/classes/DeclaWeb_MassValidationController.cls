/***
* @author Ariane Tanguy (GFI)
* @date 06/01/2021
* @description DeclaWeb_MassValidation controller
*/

public with sharing class DeclaWeb_MassValidationController {
    
    private ApexPages.StandardSetController standardController;
    
    public DeclaWeb_MassValidationController(ApexPages.StandardSetController standardController) {
        this.standardController = standardController;
    }
    
    public PageReference getCases() {
        
        // Get the selected records
        List<Case> selectedCases = (List<Case>) standardController.getSelected();
        
        // Update records       
        for(Case selectedCase : selectedCases) {
                selectedCase.Status = 'Valid';
        }
        
        return null;        
    }
    
    public PageReference updateCases() {
        return standardController.save();   
    }
}