import { LightningElement, track, api, wire } from 'lwc';
import getPJ from '@salesforce/apex/LWC_PJManageStatus.getPJ';
import updatePJ from '@salesforce/apex/LWC_PJManageStatus.updatePJ';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import NAME_FIELD from '@salesforce/schema/Piece_justificative_Sinistre__c.Name';

const FIELDS = [
    NAME_FIELD
];

const columns = [

    { label: 'Nom Pièce', fieldName: 'namePJ', editable: false },
    {
        label: 'Statut', fieldName: 'status', type: 'picklist', typeAttributes: {
            placeholder: 'Choose rating', options: [
                { label: '1-Attendue', value: 'Expected' },
                { label: '2-Reçu', value: 'Received' },
                { label: '3-Valide', value: 'Valid' },
                { label: '4-Plus réclamé', value: 'NotNeeded' },
                { label: '5-Non valide', value: 'Invalid' },
            ] 
            , value: { fieldName: 'status' } 
            , context: { fieldName: 'Id' } 
        }
    },
    { label: 'Document Lié', fieldName: 'documentLink', editable: false },
    { label: 'Commentaire', fieldName: 'commentaire', type: 'text', editable: true }
];

export default class Lwc_PJManageStatus extends LightningElement {

    columns;
    @track draftValues = [];
    @track data = [];
    @api recordId;
    @api fileId;

    lastSavedData = [];
    mapLastSaved = new Map();
    mapData = new Map();

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    pieceJusti;
    

    connectedCallback() {
        this.columns = columns;

        getPJ({fileId: this.recordId}).then(result => {
            this.data = result;
            this.lastSavedData = JSON.parse(JSON.stringify(this.data));
        });

    }

    updateDataValues(updateItem) {
        let copyData = JSON.parse(JSON.stringify(this.data));
        copyData.forEach(item => {
            if (item.Id === updateItem.Id) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
            }
        });

        //write changes back to original data
        this.data = [...copyData];
    }

    picklistChanged(event) {
        try{
            event.stopPropagation();
            let dataRecieved = event.detail.data;
            let updatedItem = { Id: dataRecieved.context, status: dataRecieved.value };
            this.updateDraftValues(updatedItem);
            this.updateDataValues(updatedItem);
            if(dataRecieved.value === 'Valid' || dataRecieved.value === 'Received'){
                let updatedItem = { Id: dataRecieved.context, documentLinkId: this.recordId};
                this.updateDraftValues(updatedItem);
                this.updateDataValues(updatedItem);
            }
        } catch(e){
            console.error(e);
            console.error('e.name => ' + e.name );
            console.error('e.message => ' + e.message );
            console.error('e.stack => ' + e.stack );
        }
        
    }

    updateDraftValues(updateItem) {
        let draftValueChanged = false;
        let copyDraftValues = JSON.parse(JSON.stringify(this.draftValues));
        
        copyDraftValues.forEach(item => {
            if (item.Id === updateItem.Id ) {
                for (let field in updateItem) {
                    item[field] = updateItem[field];
                }
                draftValueChanged = true;
            }
        });

        if (draftValueChanged) {
            this.draftValues = [...copyDraftValues];
        } else {
            this.draftValues = [...copyDraftValues, updateItem];
        }
    }

    //handler to handle cell changes & update values in draft values
    handleCellChange(event) {
        this.updateDraftValues(event.detail.draftValues[0]);
        this.updateDataValues(event.detail.draftValues[0]);
    }

    handleSave(event) {
        console.log('Updated items', JSON.parse(JSON.stringify(this.lastSavedData)));
        console.log('Updated items2', JSON.parse(JSON.stringify(this.data)));
        this.updateMap();
        
        updatePJ({listPJUpdated: this.data,IdDocument: this.recordId}).then(result => {
            console.log("save action :" + result);
            if(result.includes('error')){
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Attention',
                        message: 'Les pièces justificatives ne se sont pas mise à jour, merci de contacter votre administrateur',
                        variant: 'warning'
                    })
                );
            }
            else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Succès',
                        message: 'Les pièces justificatives ont bien été mis à jour',
                        variant: 'success'
                    })
                );
                this.draftValues = [];
                console.log();
                for (let [key, value] of this.mapData.entries()) {
                    console.log(value.status);
                    console.log(this.mapLastSaved.get(key).status);
                    if(value.status != this.mapLastSaved.get(key).status && (value.status === "Valid" || value.status === "Received") ){
                        console.log(this.pieceJusti.data);
                        let updatedItem = { Id: value.Id, documentLink: getFieldValue(this.pieceJusti.data, NAME_FIELD)};
                        this.updateDataValues(updatedItem);
                    }
                    else if(value.status != this.mapLastSaved.get(key).status && (value.status != "Valid" || value.status != "Received")){
                        let updatedItem = { Id: value.Id, documentLink: ''};
                        this.updateDataValues(updatedItem);
                    }
                }
            }
        }).catch(error => {
            console.log("save failed");
            console.log(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'ERROR',
                    message: 'Une erreur est survenue, merci de contacter votre administrateur :'+error.message,
                    variant: 'error'
                })
            );
        });
        
        //save last saved copy
        this.lastSavedData = JSON.parse(JSON.stringify(this.data));
        this.data = JSON.parse(JSON.stringify(this.lastSavedData));
        
    }

    handleCancel(event) {
        //remove draftValues & revert data changes
        this.data = JSON.parse(JSON.stringify(this.lastSavedData));
        this.draftValues = [];
    }

    updateMap(){
        this.data.forEach(obj => {
            this.mapData.set(obj.Id,obj);
          });
        this.lastSavedData.forEach(obj => {
            this.mapLastSaved.set(obj.Id,obj);
          });
    }

}