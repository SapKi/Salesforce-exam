import { LightningElement, api, wire, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import saveComment from '@salesforce/apex/InternalCommentTriggerHandler.saveComment';
import userId from '@salesforce/user/Id';
import USER_NAME_FIELD from '@salesforce/schema/User.Name';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';

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
        saveComment({ body: this.commentBody, accountId: this.recordId })
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
                this.errorMessage =
                    error?.body?.message || 'An unexpected error occurred.';
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error saving comment!',
                        message: this.errorMessage,
                        variant: 'error'
                    })
                );
            });
    }
}
