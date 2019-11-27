/**
 * Author: Doug Ayers
 * Website: https://douglascayers.com
 * GitHub: https://github.com/douglascayers-org/sfdx-mass-action-scheduler
 * License: BSD 3-Clause License
 */
public with sharing class DTG_SetupAuthWizardPageController {

    public final String orgDomainURL {
        get {
            return URL.getOrgDomainUrl().toExternalForm();
        }
    }

    public final String myDomain {
        get { return this.orgDomainURL.substringBetween( 'https://', '.my.salesforce.com' ); }
    }
    /**
     * Build the content of the apex test class as a string, and return it.
     *
     * @param className - string, name of class
     * @param methodName - string, name of method
     * @param flowName - string name of flow to be executed by this test
     * @param profileName - not yet in use - designed to support runAs, but tooling Rest api
     * Does not allow writing of classes that directly reference user or profile objects.
     *
     * @return - string full content of apex class to write over API
     * Todo: restore support for passing in profile to support runAs.
     */
    public static string buildApexPayload(String className, String methodName, String flowName, String profileName) {

        //List<Profile> testProfile = [SELECT Id FROM Profile WHERE Name =: profileName LIMIT 1];

        string apexPayload = '@IsTest\n ' +
                'public class '+ className + ' {' +
                '@IsTest\n' +
                //'public static void '+ methodName +'(){\n' +
                'public static void metadata2(){\n' +
                //'List<Profile> testProfile = [SELECT Id FROM Profile WHERE Name = \''+profileName+'\' LIMIT 1];\n' +
//                'user testUser = new User(Email = \'test\' + \'Test@test.com\', EmailEncodingKey = \'UTF-8\', ' +
//                'LastName = \'test\', LanguageLocaleKey = \'en_US\', LocaleSidKey = \'en_US\',' +
//                'ProfileId = \''+testProfile[0].Id+'\', TimeZoneSidKey = \'America/Los_Angeles\', ' +
//                'UserName = \'test3452345\' + \'Test@test.com\');' +
//                'String result = \'Success\';' +
                'String result = DeclarativeTestFramework.testRunner(\'2\');\n' +
                '//Testing only starts if metadata record is found, may return without testing start.\n' +
                'if(result != \'No test found\'){\n' +
                'System.assertEquals(\'Success\', result);\n' +
                'Test.stopTest();\n' +
                '}\n' +
                '}\n' +
                '}';
        return apexPayload;
    }
    public static String buildMetadataContainer(String methodName){
        JSONGenerator jgen = JSON.createGenerator(true);
        jgen.writeStartObject();
        jgen.writeStringField('Name', methodName);
        jgen.writeEndObject();

        return jgen.getAsString();
    }

    public static HttpRequest buildRequest(String endPointPath, String apiMethod) {
        String methodName;
        String flowName;

        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint('callout:Declarative_Tests/'+endPointPath);
        req.setMethod(apiMethod);

        return req;
    }

    public static void createAndUpdateClass(String metadataLabel) {
        List<TestFlowRun__mdt> thisTest = [SELECT Id, Flow_Api_Name__c, Run_As_Profile__c FROM TestFlowRun__mdt WHERE Label =: metadataLabel LIMIT 1];
        String flowName = '';

        if (thisTest.size() > 0) {
            flowName = thisTest[0].Flow_Api_Name__c;
            system.debug('Running ' + flowName);
        }

        // Constructs the Tooling API wrapper (default constructor uses user session Id)
        ToolingAPI tooling = new ToolingAPI();


        // Create class
        ToolingAPI.ApexClass apexClass = new ToolingAPI.ApexClass();
        //apexClass.Body = buildApexPayload(metadataLabel, flowName, flowName, 'System Administrator');
        apexClass.Body = buildApexPayload('TestOppSize_Amount1000_Medium', flowName, flowName, 'System Administrator');
        ToolingAPI.SaveResult sr = tooling.createSObject(apexClass);

        // Delete MetadataContainer
        List<ToolingAPI.MetadataContainer> containers =
                (List<ToolingAPI.MetadataContainer>)
                        tooling.query(
                                'SELECT Id, Name FROM MetadataContainer WHERE Name = \'dtf_DeployTest\'').records;
        if ( containers != null && ! containers.isEmpty() )
            tooling.deleteSObject(ToolingAPI.SObjectType.MetadataContainer, containers[0].Id);

        // Create MetadataContainer
        ToolingAPI.MetadataContainer container = new ToolingAPI.MetadataContainer();
        container.name = 'dtf_DeployTest';
        ToolingAPI.SaveResult containerSaveResult = tooling.createSObject(container);
        Id containerId = containerSaveResult.id;

        // Create ApexClassMember and associate them with the MetadataContainer
        ToolingAPI.ApexClassMember apexClassMember = new ToolingAPI.ApexClassMember();
        apexClassMember.Body = buildApexPayload(metadataLabel, flowName, flowName, 'System Administrator');
        apexClassMember.ContentEntityId = sr.id;
        apexClassMember.MetadataContainerId = containerId;
        ToolingAPI.SaveResult apexClassMemberSaveResult = tooling.createSObject(apexClassMember);

        // Create ContainerAysncRequest to deploy the Apex Classes
        ToolingAPI.ContainerAsyncRequest asyncRequest = new ToolingAPI.ContainerAsyncRequest();
        asyncRequest.metadataContainerId = containerId;
        asyncRequest.IsCheckOnly = false;
        ToolingAPI.SaveResult asyncRequestSaveResult = tooling.createSObject(asyncRequest);

        // The above starts an async background compile, the following needs repeated (polled) to confirm compilation
        ToolingApi.ContainerAsyncRequest containerAsyncRequest =
        ((List<ToolingAPI.ContainerAsyncRequest>)
        tooling.query(
        'SELECT Id, State, MetadataContainerId, CompilerErrors ' +
        'FROM ContainerAsyncRequest ' +
        'WHERE Id = \'' + asyncRequestSaveResult.Id + '\'').records)[0];
        System.debug('State is ' + containerAsyncRequest.State);

    }

    public static void createApexClass(){

        HttpRequest containerReq = buildRequest('services/data/v47.0/tooling/sobjects/MetadataContainer/','POST');
        containerReq.setBody(buildMetadataContainer('test' + String.valueOf(System.now())));
        System.debug(containerReq.getBody());
        Http containerHttp = new Http();
        HttpResponse containerRes = containerHttp.send(containerReq);
        System.debug(containerRes);
        Map<String, Object> containerResult = (Map<String, Object>)JSON.deserializeUntyped(containerRes.getBody());
        System.debug(containerResult);
        String containerId = (String)containerResult.get('Id');
        //Add error handling

        String JSONString = buildApexPayload('test', 'test', containerId, 'System Administrator');
        HttpRequest classReq = buildRequest('services/data/v47.0/tooling/sobjects/ApesClassMember/','POST');
        classReq.setBody(JSONString);
        Http classHttp = new Http();
        HttpResponse classRes = classHttp.send(classReq);
        Map<String, Object> classResult = (Map<String, Object>)JSON.deserializeUntyped(classRes.getBody());
        String classId = (String)classResult.get('Id');
        //Add error handling

        HttpRequest deployReq = buildRequest('services/data/v47.0/tooling/sobjects/ContainerAsyncRequest/', 'POST');
        Http deployHttp = new Http();
        HttpResponse deployRes = deployHttp.send(deployReq);
        Map<String, Object> deployResult = (Map<String, Object>)JSON.deserializeUntyped(deployRes.getBody());
        String deployId = (String)deployResult.get('Id');
        //Add error handling
        //Add deployment status check/feedback

    }

    /**
     * Create the container, receive the ID in response
     * Create a apexclassmember with the MetadataContainerId = the container Id
     * and the body = to the apex class body
     */
    public static string getCurrentClass(){
        System.debug(UserInfo.getLastName());
        String apexClassBody = '';
        HttpRequest req = buildRequest('services/data/v47.0/tooling/sobjects/ApexClassMember','GET');
        //HttpRequest req = buildRequest('services/data/v47.0/tooling/query/?q=SELECT+Id,FullName,Body+FROM+ApexClass+WHERE+FullName=\'DeclarativeTestRunner\'','GET');
        System.debug(req);
        Http h = new Http();
        HttpResponse res = h.send(req);
        System.debug(res.getBody());
        return apexClassBody;
    }
}
/*
BSD 3-Clause License
Copyright (c) 2017-2019, Doug Ayers, douglascayers.com
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
* Neither the name of the copyright holder nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/