/**
 * Created by chpifer on 11/4/2019.
 */

public with sharing class testDataFactory {
    public static User createUser(String profileName){

        List<Profile> testProfile = [SELECT Id FROM Profile WHERE Name =: profileName LIMIT 1];

        User u = new User(email= 'test' + 'Test@test.com',
                Alias='testUser',
                EmailEncodingKey='UTF-8', LastName='test',
                LanguageLocaleKey='en_US', LocaleSidKey='en_US',
                ProfileId = testProfile[0].Id, TimeZoneSidKey='America/Los_Angeles',
                UserName= 'test3452345' + 'Test@test.com');
        return u;
    }
}