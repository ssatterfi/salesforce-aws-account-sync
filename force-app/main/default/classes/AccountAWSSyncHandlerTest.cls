@IsTest
private class AccountAWSSyncHandlerTest {
    private class SuccessfulCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('POST', request.getMethod());
            System.assertEquals('callout:AWS_Account_Sync', request.getEndpoint());
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(request.getBody());
            System.assertEquals('Queueable Sync Test', payload.get('Name'));
            System.assertEquals('Pending', payload.get('AWS_Sync_Status__c'));

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"message":"success"}');
            return response;
        }
    }

    private class FailedCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(403);
            response.setBody('{"message":"Forbidden"}');
            return response;
        }
    }

    @IsTest
    static void insertSyncsAccountThroughQueueable() {
        Test.setMock(HttpCalloutMock.class, new SuccessfulCalloutMock());

        Test.startTest();
        Account account = new Account(Name = 'Queueable Sync Test');
        insert account;
        Test.stopTest();

        Account syncedAccount = [
            SELECT AWS_Sync_Status__c, Last_AWS_Sync_Date__c
            FROM Account
            WHERE Id = :account.Id
        ];
        System.assertEquals('Synced', syncedAccount.AWS_Sync_Status__c);
        System.assertNotEquals(null, syncedAccount.Last_AWS_Sync_Date__c);
    }

    @IsTest
    static void marksAccountFailedWhenEndpointReturnsError() {
        Test.setMock(HttpCalloutMock.class, new FailedCalloutMock());

        Test.startTest();
        Account account = new Account(Name = 'Failed Queueable Sync Test');
        insert account;
        Test.stopTest();

        Account failedAccount = [
            SELECT AWS_Sync_Status__c, Last_AWS_Sync_Date__c
            FROM Account
            WHERE Id = :account.Id
        ];
        System.assertEquals('Failed', failedAccount.AWS_Sync_Status__c);
        System.assertEquals(null, failedAccount.Last_AWS_Sync_Date__c);
    }
}
