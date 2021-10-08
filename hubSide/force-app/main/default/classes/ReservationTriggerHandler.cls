/***
* @author Ariane Tanguy (GFI)
* @date 05/05/2020
* @description Handler class for ReservationTrigger
*/

public class ReservationTriggerHandler {
    
    private static id createdReservationRecordType = UtilityClassHelper.getCreatedRecordType('Reservation');
    private static id tempResRecordType = UtilityClassHelper.getCreatedRecordType('Reservation_pre_reservee');
    
    /***
	* @description Update the record type
	* @param newReservationList - list of reservation
	* @return NA
	*/
    public static void updateRecordTypeOnCreation(List<Reservation__c> newReservationList){
        
        for(Reservation__c r : newReservationList){
            if(r.Status__c == 'Pré-réservé'){
                r.RecordTypeId = tempResRecordType;
            } else {
                r.RecordTypeId = createdReservationRecordType;
            }
        }
    }
    
    /***
	* @description Update the pre-reservation depending of the client infos
	* @param newReservationList - list of reservation
	* @param canMap - map of boolean
	* @return NA
	*/
    public static void updatePreReservation(List<Reservation__c> newReservationList, Map<id, String> cannotMap){
        
        // Loop over all the new reservations
        for(Reservation__c r : newReservationList){
            
            // If that particular reservation isnt authorized by rules 1 and 2
            if(cannotMap.keySet().contains(r.id)){
                r.Motif_pre_reservation__c = cannotMap.get(r.id);
            } else {
                if(r.Status__c == 'Pré-réservé'){
                    r.Status__c = 'Réservé';
                    r.RecordTypeId = createdReservationRecordType;
                }
            }
        }
    }
    
    /***
	* @description Update the record type
	* @param newReservationList - list of reservation
	* @param reservationRecordType - previously queried record type
	* @return NA
	*/
    public static void updateRecordTypeOnUpdate(List<Reservation__c> newReservationList, Map<id, Reservation__c> oldReservationMap){
        
        for(Reservation__c r : newReservationList){
            if(r.Status__c != oldReservationMap.get(r.Id).Status__c){
                if(r.Status__c == 'Réservation_convertie' || r.Status__c == 'Annulé'){
                   r.RecordTypeId = UtilityClassHelper.getCreatedRecordType('Reservation_convertie');
               }
                if(r.Status__c == 'Réservé'){
                    r.RecordTypeId = createdReservationRecordType;
                }
            }
        }
    }
    
    /***
	* @description When creating a reservation, check whether there isn't already an emprunt or a reservation.
	* @param newReservationList - list of new reservation
	* @param currentEmpruntList - current emprunt list
	* @param plannedReservationList - already planned reservation
	* @return NA
	*/
    public static void checkStockPlanning(List<Reservation__c> newReservationList, List<Emprunt__c> currentEmpruntList, List<Reservation__c> plannedReservationList){
                
        // Loop over the new reservation
        for(Reservation__c r : newReservationList){
            
            system.debug('-- here r ' + r);
            
            r.Stock_disponible__c = TRUE;
            
            if(r.Date_retrait__c == NULL || r.Duree_emprunt__c == NULL){
                break;
            }
            
            system.debug('-- here currentEmpruntList ' + currentEmpruntList);
            
            // Then over the current emprunt
            for(Emprunt__c currentEmprunt : currentEmpruntList){
                
                system.debug('-- here currentEmprunt ' + currentEmprunt);
                
                if(UtilityClassHelper.compareDate(currentEmprunt.Date_sortie__c, 
                                                  currentEmprunt.Date_retour_prevu__c, 
                                                  r.Date_retrait__c, 
                                                  r.Date_retrait__c.addDays((Integer)r.Duree_emprunt__c)) && 
                   r.Produit_reserve__c == currentEmprunt.Produit_emprunte__c &&
                   currentEmprunt.Nombre_jours_depassement__c < 0){
                       r.Stock_disponible__c = FALSE;
                       system.debug('--- FALSE');
                       break;
                   }
            }
            
            // And finally over the reservation, if the stock is still not taken
            if(r.Stock_disponible__c){
                
                system.debug('-- here plannedReservationList ' + plannedReservationList);
                
                for(Reservation__c plannedRes : plannedReservationList){
                    
                    system.debug('-- here plannedRes ' + plannedRes);
                    
                    if(UtilityClassHelper.compareDate(plannedRes.Date_retrait__c, 
                                                      plannedRes.Date_retrait__c.addDays((integer)r.Duree_emprunt__c), 
                                                      r.Date_retrait__c, 
                                                      r.Date_retrait__c.addDays((Integer)r.Duree_emprunt__c)) && 
                       plannedRes.Produit_reserve__c == r.Produit_reserve__c){
                           r.Stock_disponible__c = FALSE;
                               system.debug('--- FALSE');                        
                           break;
                       }
                }
            }
            // If the date was 30 days + away from today's date, create it anyway, and may the odds be in your favor
            if(!r.Stock_disponible__c &&
               r.Date_retrait__c > system.today() + 30){
                   r.Status__c = 'Pré-réservé';
                   r.RecordTypeId = tempResRecordType;
                   r.Motif_pre_reservation__c = 'Hors stock';
                   r.Stock_disponible__c = TRUE;
               }
        }
    }
    
    /***
	* @description Update the related stock
	* @param newReservationList - list of reservation
	* @param reservationRecordType - previously queried record type
	* @return NA
	*/
    public static void updateRelatedStock(List<Reservation__c> newReservationList, List<Stock_produit__c> relatedStockList){
                
        // Map the reservation to their stock
        Map<id, List<Reservation__c>> stockIdReservationMap = new Map<id, List<Reservation__c>>();
        for(Reservation__c r : newReservationList){
            if(!stockIdReservationMap.keySet().contains(r.Produit_reserve__c)){
                List<Reservation__c> tmpList = new List<Reservation__c>();
                stockIdReservationMap.put(r.Produit_reserve__c, tmpList);
            }
            stockIdReservationMap.get(r.Produit_reserve__c).add(r);
        }
        
        // Loop over the stocks to update them
        for(Stock_produit__c s : relatedStockList){
            
            if(stockIdReservationMap.keySet().contains(s.id)){
                
                // Loop over the related reservations
                for(Reservation__c r : stockIdReservationMap.get(s.id)){
                    
                    if(s.Prochaine_reservation__c == r.id && 
                       s.Date_retrait_souhaitee__c != r.Date_retrait__c){
                           s.Date_retrait_souhaitee__c = r.Date_retrait__c;
                       }
                    
                    if(s.Date_retrait_souhaitee__c > r.Date_retrait__c ||
                       s.Date_retrait_souhaitee__c == NULL){
                           s.Prochaine_reservation__c = r.id;
                           s.Date_retrait_souhaitee__c = r.Date_retrait__c;
                       }
                }                
            }
        }
        
        update relatedStockList;
    }
}