import LightningDatatable from 'lightning/datatable';
import DatatablePicklistTemplate from './picklistTemp.html';
import CustomDataTableResource from '@salesforce/resourceUrl/CustomDataTable';
import {
    loadStyle
} from 'lightning/platformResourceLoader';

export default class CustomDatatable extends LightningDatatable {
    static customTypes = {
        picklist: {
            template: DatatablePicklistTemplate,
            typeAttributes: ['placeholder', 'options', 'value', 'context'],
        },

    };

    constructor() {
        super();
        Promise.all([
            loadStyle(this, CustomDataTableResource),
        ]).then(() => {})
    }
}