@isTest
private class Test_BillAPI {
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>{
            new Account(Name = 'Test Account 1', Active__c = 'Yes'),
            new Account(Name = 'Test Account 2', Active__c = 'Yes'),
            new Account(Name = 'Inactive Account', Active__c = 'No')
        };
        insert testAccounts;
    }
    
    @isTest
    static void testGetBillsSuccess() {
        // Set up the mock callout response
        Test.setMock(HttpCalloutMock.class, new BillAPIMockHttpResponseGenerator(200, 
            '[{"billId": "BILL-001", "accountName": "Test Account 1", "balance": "$100.00"},' +
            '{"billId": "BILL-002", "accountName": "Test Account 2", "balance": "$200.00"},' +
            '{"billId": "BILL-003", "accountName": "Inactive Account", "balance": "$300.00"}]'));
        
        Test.startTest();
        BillAPI.getBills();
        Test.stopTest();
        
        // Verify results
        List<Bill__c> upsertedBills = [SELECT Id, Bill_Number__c, Balance__c, Account__c FROM Bill__c];
        System.assertEquals(2, upsertedBills.size(), 'Two bills should be upserted');
        
        for (Bill__c bill : upsertedBills) {
            System.assert(bill.Account__c != null, 'Account lookup should be populated');
            System.assert(bill.Bill_Number__c.startsWith('BILL-'), 'Bill Number should start with BILL-');
            System.assert(bill.Balance__c > 0, 'Balance should be positive');
        }
    }
    
    @isTest
    static void testGetBillsHttpError() {
        // Set up the mock callout response with an error status code
        Test.setMock(HttpCalloutMock.class, new BillAPIMockHttpResponseGenerator(500, 'Internal Server Error'));
        
        Test.startTest();
        BillAPI.getBills();
        Test.stopTest();
        
        // Verify no bills were upserted
        List<Bill__c> upsertedBills = [SELECT Id FROM Bill__c];
        System.assertEquals(0, upsertedBills.size(), 'No bills should be upserted on HTTP error');
    }
    
    @isTest
    static void testGetBillsInvalidJson() {
        // Set up the mock callout response with invalid JSON
        Test.setMock(HttpCalloutMock.class, new BillAPIMockHttpResponseGenerator(200, 'Invalid JSON'));
        
        Test.startTest();
        BillAPI.getBills();
        Test.stopTest();
        
        // Verify no bills were upserted
        List<Bill__c> upsertedBills = [SELECT Id FROM Bill__c];
        System.assertEquals(0, upsertedBills.size(), 'No bills should be upserted on invalid JSON');
    }
    
    @isTest
    static void testGetBillsInvalidBalance() {
        // Set up the mock callout response with an invalid balance
        Test.setMock(HttpCalloutMock.class, new BillAPIMockHttpResponseGenerator(200, 
            '[{"billId": "BILL-001", "accountName": "Test Account 1", "balance": "Invalid"}]'));
        
        Test.startTest();
        BillAPI.getBills();
        Test.stopTest();
        
        // Verify no bills were upserted due to invalid balance
        List<Bill__c> upsertedBills = [SELECT Id FROM Bill__c];
        System.assertEquals(0, upsertedBills.size(), 'No bills should be upserted with invalid balance');
    }
    
    @isTest
    static void testGetBillsNoActiveAccounts() {
        // Delete all active accounts
        delete [SELECT Id FROM Account WHERE Active__c = 'Yes'];
        
        // Set up the mock callout response
        Test.setMock(HttpCalloutMock.class, new BillAPIMockHttpResponseGenerator(200, 
            '[{"billId": "BILL-001", "accountName": "Test Account 1", "balance": "$100.00"}]'));
        
        Test.startTest();
        BillAPI.getBills();
        Test.stopTest();
        
        // Verify no bills were upserted
        List<Bill__c> upsertedBills = [SELECT Id FROM Bill__c];
        System.assertEquals(0, upsertedBills.size(), 'No bills should be upserted when there are no active accounts');
    }
    
    // Mock HTTP Callout Response Generator
    private class BillAPIMockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String body;
        
        public BillAPIMockHttpResponseGenerator(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }
        
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(statusCode);
            response.setBody(body);
            return response;
        }
    }
}