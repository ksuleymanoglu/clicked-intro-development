public with sharing class BillAPI {
    public static void getBills() {
        try {
            //Step 1: Query for active accounts
            Map<String, Id> activeAccountMap = new Map<String, Id>();
            for (Account acc : [SELECT Id, Name FROM Account WHERE Active__c = 'Yes' ]) {
                activeAccountMap.put(acc.Name, acc.Id);
            }

            // Step 2: Set up and send the HTTP request
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            //request.setEndpoint('callout:MyNamedCred/bills');
            request.setEndpoint('https://my-json-server.typicode.com/walters954/clicked-intro-development-server/bills');
            request.setMethod('GET');
            HttpResponse response = http.send(request);

            // Step 3: Process the HTTP response
            if (response.getStatusCode() == 200) {
                // Get the response body as a string
                String jsonResponse = response.getBody();
                
                // Deserialize the JSON string into a list of BillWrapper objects
                List<BillWrapper> billWrappers = (List<BillWrapper>)JSON.deserialize(jsonResponse, List<BillWrapper>.class);

                // Step 4: Convert BillWrapper objects to Bill__c records
                List<Bill__c> billsToUpsert = new List<Bill__c>();
                for (BillWrapper wrapper : billWrappers) {
                    // Check if the account name is in the active accounts map
                    if (activeAccountMap.containsKey(wrapper.accountName)) {
                        Bill__c newBill = new Bill__c();
                        newBill.Bill_Number__c = wrapper.billId;                        
                        newBill.Account__c = activeAccountMap.get(wrapper.accountName);
                        
                        // Use a try/catch block for the balance conversion
                        try {
                            newBill.Balance__c = Decimal.valueOf(wrapper.balance.replace('$', ''));
                        } catch (Exception e) {
                            // Log the error and skip this bill if balance conversion fails
                            System.debug('Error converting balance for bill ' + wrapper.billId + ': ' + e.getMessage());
                            continue;
                        }
                        
                        billsToUpsert.add(newBill);
                    }
                }

                // Step 5: Upsert the bills
                if (!billsToUpsert.isEmpty()) {
                    upsert as User billsToUpsert;
                    System.debug('Successfully upserted ' + billsToUpsert.size() + ' bills.');
                } else {
                    System.debug('No bills to upsert.');
                }
            } else {
                // Handle non-200 status codes
                System.debug('HTTP Request failed with status code: ' + response.getStatusCode());
            }
        } catch (System.CalloutException e) {
            // Handle callout errors (e.g., network issues, timeout)
            System.debug('Callout error: ' + e.getMessage());
        } catch (System.JSONException e) {
            // Handle JSON parsing errors
            System.debug('JSON parsing error: ' + e.getMessage());
        } catch (System.DmlException e) {
            // Handle DML errors (e.g., validation rules, trigger errors)
            System.debug('DML error: ' + e.getMessage());
        } catch (Exception e) {
            // Handle any other unexpected errors
            System.debug('Unexpected error: ' + e.getMessage());
        }
    }

     public class BillWrapper {
        public String billId;
        public String accountName;
        public String balance;
    }
}