# DeclarativeTestGeneration

### Project Vision (Your first task as a team)
**The dream** - I can create an autolaunch flow, declare it as a "test" flow, add standard flow components to test any functionality in my org, drop-in an assertion component, and run my flow as part of the standard apex test tooling, providing code coverage and all the functionality of a first-class unit test.  The platform just doesn't support this dream out of the box. Acknowledging this limitation, the sprint group asked the question: how close can we get to this goal in spite of platform limitations?

**What is here** - This is a proof of concept and a proposed design pattern for exchange of data between auto-launched visual flows and apex tests. It allows for Visual Flows to be a full-fledged, first-class citizen in the testing world, with all test logic and assertions living within a visual flow. Apex is only used as a wrapper to interact with the standard apex testing tools.

With time, investment, and community contributions this could be developed into an open-source package (see to do list!). 

**Who is this for** - This framework and test functionality would be most helpful for administrators and implementation partners adding declarative customizations to Salesforce organizations where code maintenance is not practical.

**How do I use it?**
1. Install it (CumulusCI config included in the repo)
1. Create a standard auto-launch flow.  
1. Test any assertions in the flow using a decision or formula and assign the result to a variable called 'result'.  If the test fails, store a meaningful error message describing the error to the result variable.  Make sure you catch any DML errors.
1. Create a new entry in the Test Flow Run custom metadata type.  
1. Set the label to a number, currently 1 and 2 are examples of passing and failing tests.  3-12 are available with the current code, but code can be modified with cut and paste to support more flows with copy and paste.  This is a stop-gap approach (see to-do)
1. Enter the api name of the flow and, optionally, enter a profile name if you want the flow to run as a non-admin user.
1. Open the dev console or your favorite test runner and run the declarative test runner test class.
See the wiki for more details on how this works and how it can be extended.

Current test framework is handled by APEX code and is not easily applicable to declarative customization. A test framework for declarative automation, with a regression test function created using Flow, administrators could create new customizations without worrying about whether a validation rule or Process Builder automation was breaking other components of their organization.

### Project Team
* Team Leader(s): Chris Pifer
* GitHub Scribe(s): Brian Ricter, Fatma Ahmed
* List of all Contributors: Jim Letts, Jason Cook, Brian Weldon

### Project Resources
* Wiki within this repository contains Business Requirements and Limitations.

### Project Team Accomplishments
1. Created the "Business Requirements" wiki page that explains the specs for a "crawl" phase
1. Create the "Solution Components" wiki page
1. Created template APEX class
1. Demonstrated proof of concept with test flows for Workflow Rules and Process Builder, successfully retrieving 'result' variable string from flows.

### Future Contributions (AKA what were you unable to finish at the Sprint)

1. Develop UI for end users to create custom metadata without requiring the setup UI.  
1. Current code relies on a single apex test class to call flows.  This should be deprecated and replaced with a button that dynamically generates and deploys an apex test class per custom metadata record over the ToolingAPI using the template metadata record.
1. Modify template class to guarantee running user uniqueness (Username must be unique globally across test and production usernames).
1. Assert test if flow is active
1. Consider returning a custom apex container object to provide for better options for flow of information between test code and flows returning more comprehensive result object out of flow
More details on this in the repo.

## Development

To work on this project in a scratch org:

1. [Set up CumulusCI](https://cumulusci.readthedocs.io/en/latest/tutorial.html)
1. Run `cci flow run dev_org --org dev` to deploy this project.
1. Note - this build will fail due to the need to deploy static resources.  Currently the work-around is to run cci org browser --org dev and manually create static resources named jquery and jsforce in the org, they try 'cci flow run dev_org --org dev' to complete the build.
3. Run `cci org browser dev` to open the built org in your browser.
