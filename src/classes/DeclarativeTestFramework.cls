/**
 * Created by chpifer on 11/4/2019.
 */

global with sharing class DeclarativeTestFramework {
    global static string testRunner(String runNumber) {

        string result; //variable that will record the result of the test flow
        string profileName; //variable to store run as profile
        string flowName;
        List<TestFlowRun__mdt> thisTestRun = [SELECT Id, Flow_Api_Name__c, Run_As_Profile__c FROM TestFlowRun__mdt WHERE Label = :runNumber LIMIT 1];
        if (thisTestRun.size() > 0) {
//            if (thisTestRun[0].Run_As_Profile__c == null) {
//                profileName = 'System Administrator';
//            } else {
//                profileName = thisTestRun[0].Run_As_Profile__c;
//            }
            flowName = thisTestRun[0].Flow_Api_Name__c;
            system.debug('Running ' + flowName);

            //list<profile> testProfile = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];

            //start the test

            Map<String, Object> nothing = new Map<String, Object>();
            Test.startTest();

            //run the test as a test user with the chosen profile

                Flow.Interview testFlow = Flow.Interview.createInterview(flowName, nothing);

                //Check to ensure that the flow is found and if it is run it.
                if (testFlow != null) {
                    testFlow.start();
                    result = (string) (testFlow.getVariableValue('result'));
                }
        } else {
            //No metadata found, assume no test to run here.
            System.debug('No flowTestRunner metadata found for run ' + runNumber + ', nothing to test.' +
                    'If you expected a test to run, check your metadata naming');
            result = 'No test found';
        }

        return result;
    }
}