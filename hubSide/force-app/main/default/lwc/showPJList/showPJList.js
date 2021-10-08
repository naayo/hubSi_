import { LightningElement, api, wire, track } from 'lwc';
import getUserProfile from '@salesforce/apex/GEDController.getUserProfile';
import getPJList from '@salesforce/apex/GEDController.getPJList';
import getPJOptions from '@salesforce/apex/GEDController.getPJOptions';
import updatePJ from '@salesforce/apex/GEDController.updatePJ';

export default class showPJList extends LightningElement {
    @api recordId;
    @wire(getUserProfile) canUserEdit;
    @wire(getPJList, { documentId: '$recordId' }) pjObjectList;

    pjOptions = [];

    @wire(getPJOptions)
    wiredFieldValue({ error, data }) {
        if (data) {
            this.pjOptions = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.pjOptions = undefined; 
        }
    }

    // Maps file ID and title to tab value and label
    get options() {
        if (!this.pjOptions) return [];

        const options = [];
        const files = Object.entries(this.pjOptions);
        for (const [label, value] of files) {
            options.push({
                label: label,
                value: value
            });
        }        
        return options;
    }

    handleChange(event) {
        this.value = event.detail.value;
        updatePJ({pjId: event.target.id, newValidity: event.detail.value, documentId: this.recordId})
    }

    refreshPage() {
        window.location.reload()
    }
}