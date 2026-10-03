// AccountAWSSyncHandler.cls synce with AWS for Account records.
// This class handles the callout to AWS and updates the Account records with the 
//sync status.
public class AccountAWSSyncHandler {

    public static void handleAccounts(List<Account> accounts) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        doCalloutAndUpdate(accountIds);
    }

    @future(callout=true)
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
            req.setBody(JSON.serialize(payload));
            req.setTimeout(120000);

            try {
                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                    acc.AWS_Sync_Status__c = 'Synced';
                    acc.Last_AWS_Sync_Date__c = System.now();
                } else {
                    acc.AWS_Sync_Status__c = 'Failed';
                }
            } catch (Exception e) {
                acc.AWS_Sync_Status__c = 'Failed';
                System.debug('Callout error: ' + e.getMessage());
            }

            toUpdate.add(acc);
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}