import { LightningElement, wire, track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { refreshApex } from '@salesforce/apex';
import ALERT_OBJECT from '@salesforce/schema/Alert__c';
import ALERT_VALIDATION_REASON_FIELD from '@salesforce/schema/Alert__c.Validation_Reason__c';
import getApprovals from '@salesforce/apex/LWC_MassApprovalController.getApprovals';
import approvedOrRejected from '@salesforce/apex/LWC_MassApprovalController.approvedOrRejected';
import { getPicklistValues , getObjectInfo } from 'lightning/uiObjectInfoApi';
import strUserId from '@salesforce/user/Id';




const columns = [
    { label: 'Sinistre', fieldName: 'sinistre', fixedWidth: 109, type: 'url',sortable : true, typeAttributes: {label: { fieldName: 'sinistreName' }, target: '_blank'}},
    { label: 'Montant', fixedWidth: 100, fieldName: 'montantSin',sortable : true },
    { label: 'Demandeur', fixedWidth: 150, fieldName: 'caller',sortable : true },
    { label: 'Nom client',fixedWidth: 250, fieldName: 'nomClient',sortable : true },
    { label: 'Description approbation', initialWith: 1400, fieldName: 'alertsOrInfos', type: "richText", wrapText: true },
    { label: 'Formule', fieldName: 'formule',sortable : true }
];
export default class ApexDatatableExample extends LightningElement {


    error;
    columns = columns;
    @track listSinistreNotRunPaiement = new Map();
    @track allApprovalData;
    @track sortBy='sinistreName';
    @track sortDirection='desc';
    @track setSelectedRows = [];
    @track options = [];
    wiredResults;
    

    /* Use imperative method to manage refreshApex see : https://salesforce.stackexchange.com/questions/251782/cant-get-refreshapex-to-work-in-lwc*/
    @wire(getApprovals) imperativeWiring(result) {
        this.wiredResults = result;
        if (result.data) {
            this.allApprovalData =  result.data.map(
            record => Object.assign({ "sinistre" :  '/' + record.sinistreId},record)
            );
            this.sortData(this.sortBy, this.sortDirection);
        }
    }

    @wire(getObjectInfo, { objectApiName: ALERT_OBJECT }) alertMetaData;

    @wire(getPicklistValues,
        {
            recordTypeId: '$alertMetaData.data.defaultRecordTypeId', 
            fieldApiName: ALERT_VALIDATION_REASON_FIELD
        }
    ) alertValidationReasonPicklist

    @track isModalOpen = false;
    @track isApprobation = false;
    @track isRejection = false;
    @track showApprovalReasonDropDown = false;
    @track comment;
    @track validationReason;

    doSorting(event) {
        let sortbyField = event.detail.fieldName;
        if (sortbyField === "sinistre") {
            this.sortBy = "sinistreName";
        } else {
            this.sortBy = sortbyField;
        }
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
        this.sortBy = sortbyField;
        
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.allApprovalData));
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.allApprovalData = parseData;
    }  

    openModalApprobation() {
        this.listSinistreNotRunPaiement = new Map();
        var table = this.template.querySelector('lightning-datatable');
        var listSelected = table.getSelectedRows();
        console.log(listSelected);
        var rows = table.data;
        var allSinistre = [];
        rows.forEach(function(element){
            allSinistre.push(element.sinistreName);
        });
        this.checkAllItemGroupedSelected(listSelected,allSinistre);
        if(this.checkItemSelected()){
            this.isModalOpen = true;
            this.isApprobation = true;
            this.showApprovalReasonDropDown = listSelected.some( elt => elt.isAlert == true);
        }
        console.log(this.listSinistreNotRunPaiement);
    }
    openModalRejection() {
        if(this.checkItemSelected()){
            this.isModalOpen = true;
            this.isRejection = true;
        }
    }
    closeModal() {
        this.isModalOpen = false;
        this.isApprobation = false;
        this.isRejection = false;
    }
    submitDetails() {
        // to close modal set isModalOpen tarck value as false
        debugger;
        var listSelected = this.template.querySelector('lightning-datatable').getSelectedRows();
        var pType = this.isApprobation == true ? true : false;
        var mapIdApprovalApprovalProcess = {};
        var com = this.template.querySelector('lightning-input').value;
        let vReason = '';

        if(this.showApprovalReasonDropDown)
            vReason = this.template.querySelector('lightning-combobox').value;

        let userId = strUserId;
        for (const element of listSelected) {
            mapIdApprovalApprovalProcess[element.idApproval] = element.approvalProcessName;
        }
        
        approvedOrRejected({mapIdRecordApprovalProcess: mapIdApprovalApprovalProcess,processType : pType,comment : com, validationReason: vReason, userId: userId}).then(result => {
            console.log("approval update!" + result);
            if(result.includes('Not processing')){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Attention',
                        message: 'Les sinistres ne sont pas mis à jour, merci de contacter votre administrateur',
                        variant: 'warning'
                    })
                );
            }
            else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Succès',
                        message: 'Les sinistres ont bien été mis à jour',
                        variant: 'success'
                    })
                );
            }
            this.setSelectedRows = [];
            return refreshApex(this.wiredResults);
        }).catch(error => {
            console.log("approval failed!");
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'ERROR',
                    message: 'Une erreur est survenue, merci de contacter votre administrateur :'+error.message,
                    variant: 'error'
                })
            );
        });

        this.isModalOpen = false;
        this.isApprobation = false;
        this.isRejection = false;
    }

    checkItemSelected(){
        var listSelected = this.template.querySelector('lightning-datatable').getSelectedRows();

        if(listSelected && listSelected.length == 0){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Attention',
                    message: 'Merci de séléctionner au moins un sinistre',
                    variant: 'warning'
                })
            );
            return false;
        }
        return true;
    }

    checkAllItemGroupedSelected(listSelected,allRecord){
        const mapAllData = new Map();

        for (const element of allRecord) {
            if(mapAllData.get(element) == undefined){
                mapAllData.set(element, 1);
            }
            else {
                var currentElement = mapAllData.get(element);
                mapAllData.set(element, currentElement+1);
            } 
        }
        const mapSelectedData = new Map();
        for (const element of listSelected) {
            if(mapSelectedData.get(element['sinistreName']) == undefined){
                mapSelectedData.set(element['sinistreName'], 1);
            }
            else {
                var currentElement = mapSelectedData.get(element['sinistreName']);
                mapSelectedData.set(element['sinistreName'], currentElement+1);
            } 
        }
        var sinistreNotAllSelected = "";
        for (const key of mapSelectedData.keys()) {
            console.log('Selected :' + mapSelectedData.get(key));
            console.log('alldata :' + mapAllData.get(key));
            if(mapSelectedData.get(key) < mapAllData.get(key)){
                this.listSinistreNotRunPaiement.set(key,0);
                if(sinistreNotAllSelected == ""){
                    sinistreNotAllSelected = key;
                }
                else {
                    sinistreNotAllSelected = sinistreNotAllSelected + "," + key;
                }
            }
        }

        if(sinistreNotAllSelected != ""){
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Attention',
                    message: 'Vous n\'avez pas sélectionné toutes les approbations de vos sinistres : '+ sinistreNotAllSelected,
                    variant: 'warning'
                })
            );
        }

    }
}