/**
 * Created by chpifer on 10/24/2019.
 */

public with sharing class ApiWrapper {


    public static string buildApexPayload(String methodName, String flowName) {
        string apexPayload = '@IsTest\\n' +
                'static void '+ methodName +'(){\\n' +
                'String result = testRunner('+ flowName +');\\n' +
                '//Testing only starts if metadata record is found, may return without testing start.\\n' +
                'if(Test.isRunningTest()){\\n' +
                'System.assertEquals(\'Success\', result);\\n' +
                'Test.stopTest();\\n' +
                '}';
        return apexPayload;
    }

    public static HttpRequest buildRequest(String endPointPath, String apiMethod) {
        String methodName;
        String flowName;

        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint('callout:DeclarativeTestRunner/'+endPointPath);
        req.setMethod(apiMethod);

        return req;
    }

    public static string getCurrentClass(){
        System.debug(UserInfo.getLastName());
        String apexClassBody = '';
        HttpRequest req = buildRequest('query/?q=SELECT+Id,Name,Body,Metadata+FROM+ApexClassMember+WHERE+Name=DeclarativeTestRunner','GET');
        System.debug(req);
        Http h = new Http();
        HttpResponse res = h.send(req);
        System.debug(res.getBody());
        return apexClassBody;
    }
}