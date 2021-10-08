/***
* @author Ariane Tanguy (GFI)
* @date 12/06/2020
* @description Email Handler class for EmpruntTrigger
*/

public class EmpruntEmailHandler {
        
    static Id sortieEmailTemplateId = [SELECT id FROM EmailTemplate WHERE developername =: System.Label.Location_EmailTemplate_BonSortie].id;
    static Id retourEmailTemplateId = [SELECT id FROM EmailTemplate WHERE developername =: System.Label.Location_EmailTemplate_BonRetour].id;
    
    /***
	* @description Check the emprunt status and do the necessary operations
	* @param newEmpruntList - list of emprunt
	* @return NA
	*/
   	@future(callout = true)
    public static void sendEmailWithAttachment(id empruntId, String empruntStatus, String emailClient, String fileName){
        
        PageReference bonLocationPage;
        
            
        // Generate the pdf with the visual force page
        if(empruntStatus == 'Sortie'){
            bonLocationPage = Page.Location_BonDeSortie;
        } else {
            // create another template
            bonLocationPage = Page.Location_BonDeRetour;
        }
        
        bonLocationPage.getParameters().put('id', empruntId);
        
        // Take the blob out of it
        Blob pdfBlob;
        if (Test.IsRunningTest()){
            pdfBlob = Blob.valueOf('UNIT.TEST');
        } else {
            pdfBlob = bonLocationPage.getContentAsPDF();
        }
        
        // Generate the attachment
        Messaging.EmailFileAttachment bonLocationAttachment = new Messaging.EmailFileAttachment();
        bonLocationAttachment.setFileName(filename);
        bonLocationAttachment.setBody(pdfBlob);
        
        // Upload all the pdfs
        insertFile(empruntId, pdfBlob, fileName);
        
        // And send the emails
        //sendEmail(empruntId, empruntStatus, emailClient, bonLocationAttachment);
    }
    
    /***
	* @description Insert the attachment
	* @param newEmpruntList - list of emprunt
	* @param empruntIdBlobMap - emprunt id mapped to blob
	* @return NA
	*/
    public static void insertFile(Id empruntId, Blob currentBlob, String fileName) {
        
        ContentVersion newContentVersion = new ContentVersion();
        newContentVersion.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
        newContentVersion.PathOnClient = fileName; // The file name /!\ extension
        newContentVersion.Title = fileName; // Display name
        // converting the binary String to Blog
        newContentVersion.VersionData = currentBlob;// EncodingUtil.base64Decode(EncodingUtil.base64Encode(currentBlob)); 
        insert newContentVersion;
        
        // Get the content document Id from ContentVersion
        Id contentDocumentId = [SELECT ContentDocumentId 
                                FROM ContentVersion 
                                WHERE Id =: newContentVersion.id].ContentDocumentId;
                        
        // Create the ContentDocumentLink                    
        ContentDocumentLink newContentDocLink = new ContentDocumentLink();
        newContentDocLink.ContentDocumentId = contentDocumentId;
        newContentDocLink.LinkedEntityId = empruntId; // could be objectId, GroupId or any other id
        newContentDocLink.ShareType = 'V'; //'I'; // Inferred permission, see ContentDocumentLink Object
        newContentDocLink.Visibility = 'AllUsers'; // 'InternalUsers';        
        insert newContentDocLink;
    }
    
    /***
	* @description Send the emails
	* @param newEmpruntList - list of emprunt
	* @param empruntIdAttachmentMap - emprunt id mapped to attachment
	* @return NA
	*//*
    public static void sendEmail(Id empruntId, String empruntStatus, String emailClient, Messaging.EmailFileAttachment currentAttachment){
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{emailClient, 'ariane.tanguy@gfi.fr'});
        
        if(empruntStatus == 'Sortie'){
            //mail.setSubject('[Location SFAM] Votre bon de sortie');
            mail.setTemplateId(sortieEmailTemplateId);
        } else {
            //mail.setSubject('[Location SFAM] Votre bon de retour');
            mail.setTemplateId(retourEmailTemplateId);
        }
        
        id contactId = [SELECT id FROM Contact WHERE Email =: emailClient][0].id;
        
        mail.setTargetObjectId(contactId);
        mail.setWhatId(empruntId);
        mail.setFileAttachments(new List<Messaging.Emailfileattachment>{currentAttachment});
        system.debug('-- here mail ' + mail);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
    }*/
}