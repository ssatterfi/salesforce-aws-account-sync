// AccountAWSSyncHandler.cls synce with AWS for Account records.
// This class handles the callout to AWS and updates the Account records with the 
//sync status.
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
                   AWS_Sync_Status__c, Last_AWS_Sync_Date__c
            FROM Account
            WHERE Id IN :accountIds
        ];

        List<Account> toUpdate = new List<Account>();

        for (Account acc : accounts) {
            // Set status to Pending before callout
            acc.AWS_Sync_Status__c = 'Pending';

            Map<String, Object> payload = new Map<String, Object>{
                'Id'                  => acc.Id,
                'Name'                => acc.Name,
                'Industry'            => acc.Industry,
                'Phone'               => acc.Phone,
                'Website'             => acc.Website,
                'BillingCity'         => acc.BillingCity,
                'AWS_Sync_Status__c'  => acc.AWS_Sync_Status__c
            };

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:AWS_Account_Sync');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            String requestBody = JSON.serialize(payload);
            req.setBody(requestBody);
            req.setTimeout(120000);

            try {
                System.debug(LoggingLevel.DEBUG, 'AWS Account Sync request body: ' + requestBody);
                Http http = new Http();
                HttpResponse res = http.send(req);
                Integer statusCode = res.getStatusCode();

                if (statusCode >= 200 && statusCode < 300) {
                    acc.AWS_Sync_Status__c = 'Synced';
                    acc.Last_AWS_Sync_Date__c = System.now();
                } else {
                    acc.AWS_Sync_Status__c = 'Failed';
                    System.debug(LoggingLevel.ERROR,
                        'AWS Account Sync failed for Account ' + acc.Id +
                        '. HTTP ' + statusCode + ' ' + res.getStatus() +
                        '; response body: ' + res.getBody());
                }
            } catch (Exception e) {
                acc.AWS_Sync_Status__c = 'Failed';
                System.debug(LoggingLevel.ERROR,
                    'AWS Account Sync callout exception for Account ' + acc.Id +
                    ': ' + e.getTypeName() + ': ' + e.getMessage() +
                    '\n' + e.getStackTraceString());
            }

            toUpdate.add(acc);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}