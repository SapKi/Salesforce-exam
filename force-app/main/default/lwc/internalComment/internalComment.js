import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, createRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import userId from '@salesforce/user/Id';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import INTERNAL_COMMENT_OBJECT from '@salesforce/schema/Internal_Comment__c';
import BODY_FIELD from '@salesforce/schema/Internal_Comment__c.Body__c';
import ACCOUNT_FIELD from '@salesforce/schema/Internal_Comment__c.Account__c';

export default class InternalComment extends LightningElement {
    @api recordId;
    @track commentBody = '';
    @track errorMessage = '';

    @wire(getRecord, { recordId: userId, fields: [USER_NAME_FIELD] })
    currentUser;

    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_NAME_FIELD] })
    account;

    get titleClass() {
        const accountName = this.account?.data?.fields?.Name?.value;
        const userName = this.currentUser?.data?.fields?.Name?.value;
        const isMatch = accountName && userName && accountName === userName;
        return isMatch ? 'ic-title ic-title-green' : 'ic-title';
    }

    get isSaveDisabled() {
        return !this.commentBody || this.commentBody.trim() === '';
    }

    handleChange(event) {
        this.commentBody = event.target.value;
        this.errorMessage = '';
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSave() {
        const fields = {
            [BODY_FIELD.fieldApiName]: this.commentBody,
            [ACCOUNT_FIELD.fieldApiName]: this.recordId
        };

        createRecord({ apiName: INTERNAL_COMMENT_OBJECT.objectApiName, fields })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Thank you for your comment',
                        variant: 'success'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch((error) => {
                // Bonus 1: show error both inline and as toast
                this.errorMessage =
                    error?.body?.output?.errors?.[0]?.message ||
                    error?.body?.message ||
                    'An unexpected error occurred.';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error saving comment',
                        message: this.errorMessage,
                        variant: 'error'
                    })
                );
            });
    }
}
