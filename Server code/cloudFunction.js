const functions = require('firebase-functions');
const dialogflow = require('dialogflow');
const uuid = require('uuid');
// runSample();
/**
 * Send a query to the dialogflow agent, and return the query result.
 * @param {string} projectId The project to be used
 */

exports.access_dialogflow = functions.https.onRequest((request, response) => {
    var userText = request.query.userText;
    console.log(userText)
    return runSample(userText).then((json) => {

        response.send(json);
        //response.send(result);
    });
    response.end();
})

async function runSample(userText) {
    // A unique identifier for the given session
    const sessionId = uuid.v4();
    const projectId = 'covidproject-blxxjl';
    // Create a new session
    const sessionClient = new dialogflow.SessionsClient();
    const sessionPath = sessionClient.sessionPath(projectId, sessionId);

    // The text query request.
    const request = {
        session: sessionPath,
        queryInput: {
            text: {
                // The query to send to the dialogflow agent
                text: userText,
                // The language used by the client (en-US)
                languageCode: 'en-US',
            },
        },
    };

    // Send request and log result
    const responses = await sessionClient.detectIntent(request);
    console.log('Detected intent');
    const queryResult = responses[0].queryResult;
    console.log(`  Query: ${queryResult.queryText}`);
    
    console.log(`  Response: ${queryResult.fulfillmentText}`);
    if (queryResult.intent) {
        console.log(`  Intent: ${queryResult.intent.displayName}`);
    } else {
        console.log(`  No intent matched.`);
    }
    console.log(queryResult.parameters)
    const json = JSON.stringify({ text: queryResult.fulfillmentText, parameters: queryResult.parameters })

    return json;
}