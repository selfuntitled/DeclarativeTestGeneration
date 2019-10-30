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
    public static string buildApexPayload(String methodName, String flowName, Id containerId) {
        string apexPayload = '{"MetadataContainerId":"'+containerId+'",' +
                '"FullName":"'+methodName+'",' +
                '"Body":"' +
                '@IsTest\\n' +
                'static void '+ methodName +'(){\\n' +
                'String result = testRunner('+ flowName +');\\n' +
                '//Testing only starts if metadata record is found, may return without testing start.\\n' +
                'if(Test.isRunningTest()){\\n' +
                'System.assertEquals(\'Success\', result);\\n' +
                'Test.stopTest();\\n' +
                '}",' +
                'Metadata":{' +
                '"apiVersion": "39", "status": "Active"' +
                '}' +
                '}';
        String jsonPayload = JSON.serialize(apexPayload);
        return jsonPayload;
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

        String JSONString = buildApexPayload('test', 'test', containerId);
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