public with sharing class BillTriggerHandler {
    public static void validateAccountAndPopulateInvoiceNumber(List<Bill__c> newBills) {
        for (Bill__c bill : newBills) {
            // Bill Account Field Validation - this is actually not really necessary as Account__c is a required field
            if (bill.Account__c == null) {
                bill.addError('Account field cannot be null or blank.');
            }
            // Validate if Invoice Number is blank and populate with random number if so
            if (String.isBlank(bill.Invoice_Number__c)) {
                bill.Invoice_Number__c = generateInvoiceNumber();
            }                
        }
    }
    
    //generate a random (YYMMDD + unique) number as the invoice number
    private static String generateInvoiceNumber() {
        Integer randomInt = Math.abs(Crypto.getRandomInteger());
        String datePrefix = String.valueOf(Date.today().year()).right(2) + 
            String.valueOf(Date.today().month()).leftPad(2, '0') + 
            String.valueOf(Date.today().day()).leftPad(2, '0');
        String uniquePart = String.valueOf(Math.mod(randomInt, 10000)).leftPad(4, '0');
        return 'INV-' + datePrefix + '-' + uniquePart;
    }

    public static void createOpportunitiesForNewBills(List<Bill__c> newBills) {
        Set<Id> accountIds = new Set<Id>();
        for (Bill__c bill : newBills) {
            accountIds.add(bill.Account__c);
        }

        // Query for Account names
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN :accountIds WITH USER_MODE]);
        
        // Query for existing open opportunities
        Map<Id, List<Opportunity>> accountToOpenOpps = new Map<Id, List<Opportunity>>();
        for (Opportunity opp : [SELECT Id, AccountId FROM Opportunity 
                                WHERE AccountId IN :accountIds AND IsClosed = false
                                WITH USER_MODE]) {
            if (!accountToOpenOpps.containsKey(opp.AccountId)) {
                accountToOpenOpps.put(opp.AccountId, new List<Opportunity>());
            }
            accountToOpenOpps.get(opp.AccountId).add(opp);
        }
        
        // Create new opportunities if needed
        List<Opportunity> newOpportunities = new List<Opportunity>();
        for (Bill__c bill : newBills) {
            if (bill.Account__c != null && (!accountToOpenOpps.containsKey(bill.Account__c) || accountToOpenOpps.get(bill.Account__c).isEmpty())) {
                String accountName = accountMap.containsKey(bill.Account__c) ? accountMap.get(bill.Account__c).Name : 'Unknown Account';
                Opportunity newOpp = new Opportunity(
                    AccountId = bill.Account__c,
                    Amount = bill.Balance__c,
                    Name = accountName + ' - Opportunity ' + bill.Invoice_Number__c,
                    StageName = 'Prospecting',
                    CloseDate = Date.today().addDays(30)
                );
                newOpportunities.add(newOpp);
            }
        }
        
        if (!newOpportunities.isEmpty()) {
            insert as user newOpportunities;
        }
    }
}