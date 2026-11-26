// AccountAWSSyncHandler.cls
// Handles enqueuing and performing the callout to AWS for Account records.
// Updates AWS_Sync_Status__c, Last_AWS_Sync_Date__c and AWS_Sync_Error_Message__c.
public class AccountAWSSyncHandler {

    public static void handleAccounts(List<Account> accounts) {
        enqueueSync(accounts);
    }

    public static void handleAccounts(List<Account> accounts, Map<Id, Account> oldAccounts) {
        List<Account> changedAccounts = new List<Account>();
        for (Account account : accounts) {
            Account oldAccount = oldAccounts.get(account.Id);
            if (account.Name != oldAccount.Name ||
                account.Industry != oldAccount.Industry ||
                account.Phone != oldAccount.Phone ||
                account.Website != oldAccount.Website ||
                account.BillingCity != oldAccount.BillingCity) {
                changedAccounts.add(account);
            }
        }
        enqueueSync(changedAccounts);
    }

    private static void enqueueSync(List<Account> accounts) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        if (!accountIds.isEmpty()) {
            System.enqueueJob(new AccountAWSSyncQueueable(accountIds));
        }
    }

    public static void doCalloutAndUpdate(Set<Id> accountIds) {
        List<Account> accounts = [
            SELECT Id, Name, Industry, Phone, Website, BillingCity,
                   AWS_Sync_Status__c, Last_AWS_Sync_Date__c, AWS_Sync_Error_Message__c
            FROM Account
            WHERE Id IN :accountIds
        ];

        List<Account> toUpdate = new List<Account>();

        for (Account acc : accounts) {
            // Reset status before callout
            acc.AWS_Sync_Status__c = 'Pending';
            acc.AWS_Sync_Error_Message__c = null;

            Map<String, Object> payload = new Map<String, Object>{
                'Id'                  => acc.Id,
                'Name'                => acc.Name,
                'Industry'            => acc.Industry,
                'Phone'               => acc.Phone,
                'Website'             => acc.Website,
                'BillingCity'         => acc.BillingCity,
                'AWS_Sync_Status__c'  => 'Pending'
            };

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:AWS_Account_Sync');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            String requestBody = JSON.serialize(payload);
            req.setBody(requestBody);
            req.setTimeout(120000);

            try {
                System.debug(LoggingLevel.INFO, 
                    'AWS Account Sync - Starting callout for Account: ' + acc.Id + 
                    ' | Request Body: ' + requestBody);

                Http http = new Http();
                HttpResponse res = http.send(req);
                Integer statusCode = res.getStatusCode();
                String responseBody = res.getBody();

                if (statusCode >= 200 && statusCode < 300) {
                    // SUCCESS
                    acc.AWS_Sync_Status__c = 'Synced';
                    acc.Last_AWS_Sync_Date__c = System.now();
                    acc.AWS_Sync_Error_Message__c = 'Success';

                    System.debug(LoggingLevel.INFO, 
                        'AWS Account Sync SUCCESS - Account: ' + acc.Id + 
                        ' | Status Code: ' + statusCode);
                } else {
                    // FAILURE - non-2xx response
                    acc.AWS_Sync_Status__c = 'Failed';
                    acc.AWS_Sync_Error_Message__c = 'HTTP ' + statusCode + ' - ' + responseBody;

                    System.debug(LoggingLevel.ERROR, 
                        'AWS Account Sync FAILED - Account: ' + acc.Id + 
                        ' | Status Code: ' + statusCode + 
                        ' | Response: ' + responseBody);
                }
            } catch (Exception e) {
                // FAILURE - exception
                acc.AWS_Sync_Status__c = 'Failed';
                acc.AWS_Sync_Error_Message__c = e.getTypeName() + ': ' + e.getMessage();

                System.debug(LoggingLevel.ERROR, 
                    'AWS Account Sync EXCEPTION - Account: ' + acc.Id + 
                    ' | ' + e.getTypeName() + ': ' + e.getMessage() + 
                    '\nStack Trace: ' + e.getStackTraceString());
            }

            toUpdate.add(acc);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}