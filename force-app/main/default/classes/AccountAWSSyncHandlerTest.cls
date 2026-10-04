@IsTest
private class AccountAWSSyncHandlerTest {
    private class SuccessfulCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            System.assertEquals('POST', request.getMethod());
            System.assertEquals('callout:AWS_Account_Sync', request.getEndpoint());

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody('{"message":"success"}');
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
}
