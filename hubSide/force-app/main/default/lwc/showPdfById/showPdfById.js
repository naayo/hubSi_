import { LightningElement, api } from 'lwc';

export default class ShowPdfById extends LightningElement {
    @api fileId;
    @api heightInRem;
    showImage = false;

    get showImage() {
        return this.showImage;
    }

    get pdfHeight() {
        return 'height: ' + this.heightInRem + 'rem';
    }
    
    get url() {
        if(this.fileId.includes('sfc')){
            this.showImage = true;
            return this.fileId;
        } else {
            this.showImage = false;
            return '/sfc/servlet.shepherd/document/download/' + this.fileId;
        }
    }
}