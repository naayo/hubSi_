({  
	handleClick: function( component, event, helper ) {
        // search anytime the term changes
        var searchAddress = component.get( "v.searchAddress" );
        var searchZipCode = component.get( "v.searchZipCode" );
        var searchCity = component.get( "v.searchCity" );
        var caseId = component.get( "v.caseId" );
      
	    if(searchZipCode == '' || searchCity == ''){
            
            component.set("v.isError", true);
            component.set("v.messageError", 'Vous devez saisir au moins la ville et le code postal.');
            
        }else{
            component.set("v.isError", false);
            var action = component.get( "c.searchPickUp" );
            action.setParams({
                address: searchAddress,
                zipCode: searchZipCode,
                city: searchCity,
                caseId : caseId
            });
            action.setCallback( this, function(response) {
                
                
                if(response.getState() === "SUCCESS"){
                    if(response.getReturnValue() != null){
                        var res = response.getReturnValue();
                        if(res.errorCode != 0){
                        	component.set("v.isError", true);
            				component.set("v.messageError", 'La recherche point relais a généré une erreur. Veuillez contacter votre administrateur.');    
                        }else{ 
                            console.log('errorCode '+ res.errorCode);
                            var mapMarkers = [];
                            var pickUpList = res.listePointRelais;
                            for (var i = 0; i < pickUpList.length; i++) {
                                var pickUp = pickUpList[i];
                                if(pickUp.actif == true){
                                    var handicapAccess = 'Oui';
                                    if(pickUp.accesPersonneMobiliteReduite == false){
                                        handicapAccess = 'Non';    
                                    }
                                    
                                    var hoursForDescription = '';
                                    var hours = pickUp.listeHoraireOuverture;
                                    var sortedHours = new Map();                        
                                    
                                    for(var j = 0; j < hours.length; j++) {
                                        if(hours[j].jour == 1){
                                            sortedHours.set('Lundi', hours[j].horairesAsString);
                                        }else if(hours[j].jour == 2){
                                            sortedHours.set('Mardi', hours[j].horairesAsString);   
                                        }else if(hours[j].jour == 3){
                                            sortedHours.set('Mercredi', hours[j].horairesAsString);    
                                        }else if(hours[j].jour == 4){
                                            sortedHours.set('Jeudi', hours[j].horairesAsString);   
                                        }else if(hours[j].jour == 5){
                                            sortedHours.set('Vendredi', hours[j].horairesAsString);   
                                        }else if(hours[j].jour == 6){
                                            sortedHours.set('Samedi', hours[j].horairesAsString);    
                                        }else if(hours[j].jour == 7){
                                            sortedHours.set('Dimanche', hours[j].horairesAsString);    
                                        }
                                    }
                                    if(sortedHours.get('Lundi') != null && sortedHours.get('Lundi') != ''){
                                    	hoursForDescription = 'Lundi : ' + sortedHours.get('Lundi') + '<br/>';    
                                    }
                                    if(sortedHours.get('Mardi') != null && sortedHours.get('Mardi') != ''){
                                    	hoursForDescription = hoursForDescription + 'Mardi : ' + sortedHours.get('Mardi') + '<br/>';    
                                    }
                                    if(sortedHours.get('Mercredi') != null && sortedHours.get('Mercredi') != ''){
                                    	hoursForDescription = hoursForDescription + 'Mercredi : ' + sortedHours.get('Mercredi') + '<br/>';    
                                    }
                                    if(sortedHours.get('Jeudi') != null && sortedHours.get('Jeudi') != ''){
                                    	hoursForDescription = hoursForDescription + 'Jeudi : ' + sortedHours.get('Jeudi') + '<br/>';    
                                    }
                                    if(sortedHours.get('Vendredi') != null && sortedHours.get('Vendredi') != ''){
                                    	hoursForDescription = hoursForDescription + 'Vendredi : ' + sortedHours.get('Vendredi') + '<br/>';    
                                    }
                                    if(sortedHours.get('Samedi') != null && sortedHours.get('Samedi') != ''){
                                    	hoursForDescription = hoursForDescription + 'Samedi : ' + sortedHours.get('Samedi') + '<br/>';    
                                    }
                                    if(sortedHours.get('Dimanche') != null && sortedHours.get('Dimanche') != ''){
                                    	hoursForDescription = hoursForDescription + 'Dimanche : ' + sortedHours.get('Dimanche') + '<br/>';    
                                    }
                                    
                                    var marker = {
                                        'location': {
                                            'Latitude': pickUp.coordGeolocalisationLatitude,
                                            'Longitude': pickUp.coordGeolocalisationLongitude,
                                            'Street': pickUp.adresse1,
                                            'City': pickUp.localite,
                                            'PostalCode': pickUp.codePostal
                                        },
                                        'value': pickUp.identifiant + ' Address:' + pickUp.nom + ' ' + pickUp.adresse1 + ' ' + pickUp.codePostal + ' ' + pickUp.localite,
                                        'title': pickUp.nom,
                                        'description': (
                                            '<b>Distance en mètre : </b>' + pickUp.distanceEnMetre +
                                            '<br/>' +
                                            '<b>Poids maximum accepté par le point relais : </b>' + pickUp.poidsMaxi +
                                            '<br/>' +
                                            '<b>Accès aux personnes à mobilité réduite : </b>' + handicapAccess +
                                            '<br/>' +
                                            '<b>Horaires : </b> <br/>' + hoursForDescription 
                                        ),
                                        'icon': 'standard:address'
                                    };
                                    mapMarkers.push(marker);
                                }
                            }
                            component.set( 'v.mapMarkers', mapMarkers );
                        }       
                    }
                }else if (response.getState() === "ERROR"){
                    component.set("v.isError", true);
            		component.set("v.messageError", 'L\'appel vers le controller apex Salesforce n\'a pas abouti.');
                }
            });
            
            $A.enqueueAction(action);
        }
    },
    
    
    handleMarkerSelect: function (cmp, event, helper) {
       var marker = event.getParam("selectedMarkerValue");
        cmp.set("v.selectedMarkerValue", marker);
    },
    
    
    save: function( component, event, helper ) {
        
        if(component.get("v.selectedMarkerValue") != null && component.get("v.selectedMarkerValue") != ''){
            var action = component.get("c.savePickUpAddress");
            action.setParams({
                damagedEquipmentId: component.get("v.damagedEquipmentId"),
                IdExterneAndAddress: component.get("v.selectedMarkerValue")
            });
            action.setCallback( this, function(response) {
                if(response.getState() === "SUCCESS"){
                	if(response.getReturnValue() != null && response.getReturnValue() != ''){
                    	component.set("v.isError", true);
            			component.set("v.messageError", response.getReturnValue());   
                    }else{
                        var navigate = component.get('v.navigateFlow');
      					navigate('FINISH');
                    }
                    
                }else if (response.getState() === "ERROR"){
                    component.set("v.isError", true);
                    component.set("v.messageError", 'L\'appel vers le controller apex Salesforce n\'a pas abouti.');
                }
            });
            $A.enqueueAction(action);
            
        }else{
            component.set("v.isError", true);
            component.set("v.messageError", 'Vous devez sélectionner un point relais.');   
        }
    }
})