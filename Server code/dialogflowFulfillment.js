// See https://github.com/dialogflow/dialogflow-fulfillment-nodejs
// for Dialogflow fulfillment library docs, samples, and to report issues
'use strict';
 
const functions = require('firebase-functions');
const {WebhookClient} = require('dialogflow-fulfillment');
const bent = require('bent');
const getJSON = bent('json');

process.env.DEBUG = 'dialogflow:debug'; // enables lib debugging statements
 
exports.dialogflowFirebaseFulfillment = functions.https.onRequest((request, response) => {
  const agent = new WebhookClient({ request, response });
  console.log('Dialogflow Request headers: ' + JSON.stringify(request.headers));
  console.log('Dialogflow Request body: ' + JSON.stringify(request.body));
 
  function welcome(agent) {
    agent.add(`Welcome to my agent!`);
  }
 
  function fallback(agent) {
    agent.add(`I didn't understand`);
    agent.add(`I'm sorry, can you try again?`);
  }

  function worldwideLatestStats(agent) {
  const type = agent.parameters.type;
  var textToSpeak = "";
  return getJSON('https://coronavirus-tracker-api.ruizlab.org/v2/latest?source=jhu').then((result) => {
        textToSpeak += `According to my latest data, there are currently `;
        if (type.length >= 3 || type[0] == "all") {
            agent.add(`There are currently ${result.latest.confirmed} cases, ${result.latest.deaths} deaths, and ${result.latest.recovered} recovered cases of COVID-19.`);

  
          return;
    }
        for (var i = 0; i<type.length; i++){
            if (i+1 == type.length){
                textToSpeak += ', and ';
            }
            else if (i != 0){
                textToSpeak += ', ';
            }
            switch(type[i]){
                case 'confirmed':
                    textToSpeak += `${result.latest.confirmed} confimed cases`;
                    break;
                case 'deaths':
                    textToSpeak += `${result.latest.deaths} deaths`;
                    break;
                case 'recovered':
                    textToSpeak += `${result.latest.recovered} recovered`;
                    break;
            }
        }
        textToSpeak += ` of COVID-19.`;
    agent.add(textToSpeak);
    }).catch((error) =>{
    console.error(error);
    agent.add(`Sorry, I could not find those stats`);

  }); 
  }
  async function locationLatestStats(agent) {
    const type = agent.parameters.type;
    const state = agent.parameters.state;
    const country = agent.parameters.country;
    const county = agent.parameters.county;
        const city = agent.parameters.city;
        if (city.length != 0){
          agent.add("Sorry, I can not get stats for cities. Try asking for a county instead.")
        } else{
      var x = await getLocationStats(type, state, country, county, agent);
      console.log("Got stats");
            console.log(`Value is ${x}`);
        }
    //return getLocationStats(type, state, country, county, agent);
  }

  function getLocationStats(type, state, country, county, agent) {
    var finalTextToSpeak = "According to my sources,";
    return new Promise(resolve => {
      var numberOfLocationsCalculated = 0;
      if (county.length != 0) {
        //Seach by county
        for (var k = 0; k < county.length; k++) {
          var lastIndex = county[k].lastIndexOf(" ");
          var justCountyName = county[k].substring(0, lastIndex);
          var url = `https://coronavirus-tracker-api.ruizlab.org/v2/locations?source=nyt&county=${justCountyName}&timelines=false`;
          if (state.length != 0) {
            url = `https://coronavirus-tracker-api.ruizlab.org/v2/locations?source=nyt&province=${state[0]}&county=${justCountyName}&timelines=false`;
          }
          calculateStat(url, county[k], type, agent).then((textToSpeak) => {
            numberOfLocationsCalculated += 1;
                        if (textToSpeak == "undefined"){
                          agent.add("Sorry, I can not get the stats for that county.");
                        } else{
              finalTextToSpeak += textToSpeak;
                        }
                      if (numberOfLocationsCalculated+1 == county.length){
                          finalTextToSpeak += ", and";
                      } else if (numberOfLocationsCalculated != county.length){
                          finalTextToSpeak += ",";
                      }
            if (numberOfLocationsCalculated == county.length) {
              console.log("Done both");
              agent.add(finalTextToSpeak);
              resolve(10);
            }
          });
        }
      } else if (country.length != 0) {
        //Search by country
        for (var k = 0; k < country.length; k++) {
          var url = `https://coronavirus-tracker-api.ruizlab.org/v2/locations?source=jhu&country_code=${country[k]['alpha-2']}`;
          console.log(url);
          calculateStat(url, country[k]['name'], type, agent).then((textToSpeak) => {
            numberOfLocationsCalculated += 1;
            finalTextToSpeak += textToSpeak;
                        if (numberOfLocationsCalculated+1 == country.length){
                          finalTextToSpeak += ", and";
                      } else if (numberOfLocationsCalculated != country.length){
                          finalTextToSpeak += ",";
                      }
            if (numberOfLocationsCalculated == country.length) {
              console.log("Done both");
              agent.add(finalTextToSpeak);
              resolve(10);
            }
          });
        }
      }
      else if (state.length != 0) {
        //Search by state
        for (var k = 0; k < state.length; k++) {
          var url = `https://coronavirus-tracker-api.ruizlab.org/v2/locations?source=nyt&province=${state[k]}&timelines=false`;
          calculateStat(url, state[k], type, agent).then((textToSpeak) => {
            numberOfLocationsCalculated += 1;
            finalTextToSpeak += textToSpeak;
                        if (numberOfLocationsCalculated+1 == state.length){
                          finalTextToSpeak += ", and";
                      } else if (numberOfLocationsCalculated != state.length){
                          finalTextToSpeak += ",";
                      }
            if (numberOfLocationsCalculated == state.length) {
              console.log("Done both");
                            console.log(textToSpeak);
              agent.add(finalTextToSpeak);
              resolve(10);
            }
          });
        }
      } else{
              agent.add("Sorry, I cannot get the stats for that location.");
              resolve(10);
            }
    });
  }
  
  
  function calculateStat(url, state, type, agent) {
  var textToSpeak = "";
    //console.log(state[k])
    console.log("CALCULATING");
    return getJSON(url).then((result) => {
        //Loop though all stat types
        console.log(type.length);
        for (var i = 0; i < type.length; i++) {
            var typeCount = 0;
            var confirmed = 0;
            var deaths = 0;
            var recovered = 0;
            for (var j = 0; j < result.locations.length; j++) {
                switch (type[i]) {
                    case 'confirmed':
                        typeCount += result.locations[j].latest.confirmed;
                        break;
                    case 'deaths':
                        typeCount += result.locations[j].latest.deaths;
                        break;
                    case 'recovered':
                        typeCount += result.locations[j].latest.recovered;
                        break;
                    case 'all':
                        confirmed += result.locations[j].latest.confirmed;
                        deaths += result.locations[j].latest.deaths;
                        recovered += result.locations[j].latest.recovered;
                }
            }
            if (type[i] != 'all') {
                switch (type[i]) {
                case 'confirmed':
                    textToSpeak += ` there are ${typeCount} confirmed cases`;
                    break;
                case 'deaths':
                    textToSpeak += ` ${typeCount} people have died`;
                    break;
                case 'recovered':
                    textToSpeak += ` ${typeCount} people have recovered`;
                    break;
            }
            if (i+1 != type.length){
                textToSpeak += " and";
            }
            } else {
              textToSpeak += ` there are currently ${confirmed} cases, ${deaths} deaths, and ${recovered} recovered cases of COVID-19 `;
      }
        }
    textToSpeak += ` in ${state}`;
    return textToSpeak;
    }).catch((error) => {
        console.log(error);
    });
  }


  // Run the proper function handler based on the matched Dialogflow intent name
  let intentMap = new Map();
  intentMap.set('Default Welcome Intent', welcome);
  intentMap.set('Default Fallback Intent', fallback);
  intentMap.set('worldwide latest stats', worldwideLatestStats);
  intentMap.set('location latest stats', locationLatestStats);
  // intentMap.set('your intent name here', yourFunctionHandler);
  // intentMap.set('your intent name here', googleAssistantHandler);
  agent.handleRequest(intentMap);
});