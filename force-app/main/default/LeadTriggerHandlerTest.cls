@isTest
public class LeadTriggerHandlerTest {

    @isTest
    private static void testLeadTrigger_AllHandlerMethods_Positive() {
        // Create Account for Contact
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        // Matching Contact with Account
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'vp@test.com',
            AccountId = acct.Id
        );
        insert c;

        // Matching Lead
        Lead l = new Lead(
            FirstName = 'Trigger',
            LastName = 'Test',
            Company = 'TestCo',
            Title = 'VP of Engineering',
            Email = 'vp@test.com',
            Phone = '123-456-7890',
            Industry = 'Technology',
            LeadSource = 'Website'
        );

        Test.startTest();
        insert l;
        Test.stopTest(); // Ensures AFTER logic like convertLead has executed

        // Validate results
        Lead result = [SELECT Title, Lead_Score__c, IsConverted, ConvertedContactId FROM Lead WHERE Id = :l.Id];

        System.assertEquals('Vice President', result.Title, 'Title should be normalized');
        System.assertEquals(18, result.Lead_Score__c, 'Lead score should be 18');
        System.assert(result.IsConverted, 'Lead should be auto-converted');
        System.assertEquals(c.Id, result.ConvertedContactId, 'Should be converted to the correct contact');
    }

    @isTest
    private static void testLeadTrigger_NoMatchingContact_NoConvert() {
        // Lead with unique email (no matching Contact)
        Lead l = new Lead(
            FirstName = 'No',
            LastName = 'Match',
            Company = 'TestCo',
            Title = 'head of department',
            Email = 'nomatch@test.com',
            Phone = '999-999-9999',
            Industry = 'Technology',
            LeadSource = 'Website'
        );

        insert l;

        Lead result = [SELECT Title, Lead_Score__c, IsConverted FROM Lead WHERE Id = :l.Id];

        System.assertEquals('Manager', result.Title, 'Title should be normalized to Manager');
        System.assertEquals(18, result.Lead_Score__c, 'Lead score should be 18');
        System.assertEquals(false, result.IsConverted, 'Lead should not be converted');
    }

    @isTest
    private static void testLeadTrigger_MultipleContacts_NoConvert() {
        String sharedEmail = 'multi@test.com';

        // Two contacts with the same email
        insert new Contact(FirstName = 'One', LastName = 'Dup', Email = sharedEmail);
        insert new Contact(FirstName = 'Two', LastName = 'Dup', Email = sharedEmail);

        // Lead using that shared email
        Lead l = new Lead(
            FirstName = 'Too',
            LastName = 'ManyMatches',
            Company = 'TestCo',
            Title = 'Chief Marketing Officer',
            Email = sharedEmail,
            Phone = '555-1234',
            Industry = 'Technology',
            LeadSource = 'Website'
        );

        insert l;

        Lead result = [SELECT IsConverted FROM Lead WHERE Id = :l.Id];
        System.assertEquals(false, result.IsConverted, 'Lead should NOT be converted due to duplicate contacts');
    }

    @isTest
    private static void testLeadTrigger_BlankTitleOrScore() {
        // Lead with minimal info
        Lead l = new Lead(
            FirstName = 'Simple',
            LastName = 'Lead',
            Company = 'BasicCo'
            // No title, phone, email, etc.
        );

        insert l;

        Lead result = [SELECT Title, Lead_Score__c, IsConverted FROM Lead WHERE Id = :l.Id];
        System.assertEquals(null, result.Title, 'Title should remain null');
        System.assertEquals(0, result.Lead_Score__c, 'Score should be 0');
        System.assertEquals(false, result.IsConverted, 'Should not be converted');
    }
}
