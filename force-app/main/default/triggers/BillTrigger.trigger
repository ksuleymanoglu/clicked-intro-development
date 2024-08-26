trigger BillTrigger on Bill__c (before insert, after insert) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            BillTriggerHandler.validateAccountAndPopulateInvoiceNumber(Trigger.new);
        }
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        BillTriggerHandler.createOpportunitiesForNewBills(Trigger.new);
    }
}