/***
* @author Ariane Tanguy (GFI)
* @date 20/10/2020
* @description Handler class for ContentDocumentLinkTrigger
*/

public class ContentDocumentLinkTriggerHandler {
    
    /***
	* @description update emprunt on create
	* @param newEmpruntList - list of emprunt
	* @param relatedFactureList - list of related factures
	* @return NA
	*/
    public static void createContentDistribution(List<ContentVersion> contentVersionList){
        
        List<ContentDistribution> contentDistribList = new List<ContentDistribution>();
        
        for(ContentVersion cv : contentVersionList){
            
            ContentDistribution cd = new ContentDistribution();
            cd.Name = cv.Title + ' ' + system.today().day() + '/' + system.today().month() + '/' + system.today().year();
            cd.ContentVersionId = cv.Id;
            cd.PreferencesAllowViewInBrowser = TRUE;
            cd.PreferencesLinkLatestVersion = TRUE;
            cd.PreferencesNotifyOnVisit = FALSE;
            cd.PreferencesPasswordRequired = FALSE;
            cd.PreferencesAllowOriginalDownload = TRUE;
            contentDistribList.add(cd);
        }
        
        insert contentDistribList;        
    }
}