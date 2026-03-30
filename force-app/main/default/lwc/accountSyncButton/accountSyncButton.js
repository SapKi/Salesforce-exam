import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import syncAccount from '@salesforce/apex/AccountSyncButtonController.syncAccount';

export default class AccountSyncButton extends LightningElement {
    @api recordId;
    isLoading = false;

    async handleSync() {
        this.isLoading = true;
        try {
            await syncAccount({ accountId: this.recordId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Sync Queued',
                    message: 'Account sync has been queued successfully.',
                    variant: 'success'
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Sync Failed',
                    message: error?.body?.message ?? 'An unexpected error occurred.',
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
        }
    }
}
