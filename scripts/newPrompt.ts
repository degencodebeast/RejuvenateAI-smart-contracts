// const options = {
//     "What's your date of birth": [],
//     "What's your biological sex": ["Male", "Female"],
//     "What's your weight?": [],
//     "What's your height in inches?": [],
//     "Tell us about your diet?": [
//         "I eat 5 or more servings of vegetables per day",
//         "I eat two or more servings of fruit per day",
//         "I have two or more servings of dairy (or equivalent) per day",
//         "My cereals are mostly whole grains",
//         "I eat fast lean protein every day",
//         "I eat fast food once per week or less",
//         "I eat pastries or cakes once a week or less",
//         "I have less than 1 teaspoon of salt per day",
//         "I have 2 or less alcholic drinks on any day",
//         "I drink at least 2 litres of water per day",
//     ],
//     "How active are you on an average week?": [
//         "Inactive",
//         "active",
//         "very active",
//     ],
//     "How many hours a day are you sitting": [
//         0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
//         21, 22, 23, 24,
//     ],
//     "How much alchohol do you drink": [
//         "0 - 10 drinks a week",
//         "10 - 20 drinks a week",
//         "greater than 20 drinks a week",
//     ],
//     "Do you smoke?": ["Never smoked", "Ex smoker", "Current smoker"],
//     "If you are an ex-smoker, how many months ago did you stop?": [
//         "less than 6 months ago",
//         "six to twelve months ago",
//         "more than twelve months ago",
//     ],
//     "If you are a current smoker, how many cigarettes do you smoke per day?": [
//         "less than 5 cigarettes",
//         "5 to 10 cigarettes",
//         "11 to 20 cigarettes",
//         "above 20 cigarettes",
//     ],
//     "How many hours of sleep do you get per day?": [
//         0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
//     ],
//     "Rate your overall Health": [
//         "Excellent",
//         "Very good",
//         "Good",
//         "Fair",
//         "Poor",
//     ],
// };

// // const userData = {
// //     birthDate: "10 August 1990",
// //     sex: "Female",
// //     weight: "80kg",
// //     height: "5ft 5 inches",
// //     diet: ["I eat fast food once per week or less", "I have less than 1 teaspoon of salt per day" ],
// //     activity: "Inactive",
// //     sittingStatus: "10 hours",
// //     alchoholStatus: "Greater than 20 drinks a week",
// //     smokingStatus: "Current smoker",
// //     exSmokerLastSmokePeriod: "11 to 20 cigarettes per day",
// //     currentSmokerSmokePeriod: "",
// //     sleepLength: "4 hours",
// //     overallHealth: "Poor"

// // }


// // const template =
// // `   You are a robot built by rejuvenateAI. Your goal is to predict the rate of aging of users.
// //     You must respond with the following json output and nothing else. (Reverse, Fast, Moderate, Slow)

// //     example: {"aging": "Fast"}

// //     These outputs depend on the input data provided.
// //     An input data is a json object, with questions as keys and the possible answers as values.
// //     Note the values are a list of strings.

// //     example of the input data ${options}

// // `

// // const question = `

// //     Given the following:

// //     Date of Birth: ${userData?.birthDate}
// //     Sex: ${userData?.sex}
// //     Weight: ${userData?.weight}
// //     Height: ${userData?.height}
// //     Diet: ${userData?.diet}
// //     Physical Activity: ${userData?.activity}
// //     Hours Sitting Per Day: ${userData?.sittingStatus}
// //     Alcohol Rate: ${userData?.alchoholStatus}
// //     Smoking: ${userData?.smokingStatus} (${userData?.exSmokerLastSmokePeriod})
// //     Sleep Per Day: ${userData?.sleepLength}
// //     Overall Health Rating: ${userData?.overallHealth}

// //     Calculate my rate of aging?
// //     Ensure to respond with the output option on the initial condition.
// //     I know you don't have enough data but use your best understanding.
// //     Respond with either Reverse, Fast, Moderate, or Slow. Remember as a json object.
// // `

// import { Web3Storage } from 'web3.storage';

// function getAccessToken() {
//     return process.env.WEB3STORAGE_API_TOKEN
// }

// function makeStorageClient() {
//     return new Web3Storage({ token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweERiNzY2MmEyRWM2MTI3RDk2OWM5QkY1MGRFNzg2MjNGOTcwMWJjYTAiLCJpc3MiOiJ3ZWIzLXN0b3JhZ2UiLCJpYXQiOjE2Njk0MTA2Mjg5MDEsIm5hbWUiOiJrb2lpX3Rva2VuIn0.SkLCwZIK3AAwxRzb750qTMTHU4TD2uOxk590TN307zw" })
// }
// export const uploadPromptToIpfs = async (data: any) => {
//     const client = makeStorageClient();
// const prompt =
//  {
//     "template": `
    
//     You are a robot built by rejuvenateAI. Your goal is to predict the rate of aging of users.
//     You must respond with the following json output and nothing else. (Reverse, Fast, Moderate, Slow)
//     example: {"aging": "Fast"}

//     These outputs depend on the input data provided.
//     An input data is a json object, with questions as keys and the possible answers as values.
//     Note the values are a list of strings.

//     example input data in the object below
    
//     {
//         "What's your date of birth": [],
//         "What's your biological sex": ["Male", "Female"],
//         "What's your weight?": [],
//         "What's your height in inches?": [],
//         "Tell us about your diet?": [
//             "I eat 5 or more servings of vegetables per day",
//             "I eat two or more servings of fruit per day",
//             "I have two or more servings of dairy (or equivalent) per day",
//             "My cereals are mostly whole grains",
//             "I eat fast lean protein every day",
//             "I eat fast food once per week or less",
//             "I eat pastries or cakes once a week or less",
//             "I have less than 1 teaspoon of salt per day",
//             "I have 2 or less alcholic drinks on any day",
//             "I drink at least 2 litres of water per day",
//         ],
//         "How active are you on an average week?": [
//             "Inactive",
//             "active",
//             "very active",
//         ],
//         "How many hours a day are you sitting": [
//             0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
//             21, 22, 23, 24,
//         ],
//         "How much alchohol do you drink": [
//             "0 - 10 drinks a week",
//             "10 - 20 drinks a week",
//             "greater than 20 drinks a week",
//         ],
//         "Do you smoke?": ["Never smoked", "Ex smoker", "Current smoker"],
//         "If you are an ex-smoker, how many months ago did you stop?": [
//             "less than 6 months ago",
//             "six to twelve months ago",
//             "more than twelve months ago",
//         ],
//         "If you are a current smoker, how many cigarettes do you smoke per day?": [
//             "less than 5 cigarettes",
//             "5 to 10 cigarettes",
//             "11 to 20 cigarettes",
//             "above 20 cigarettes",
//         ],
//         "How many hours of sleep do you get per day?": [
//             0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
//         ],
//         "Rate your overall Health": [
//             "Excellent",
//             "Very good",
//             "Good",
//             "Fair",
//             "Poor",
//         ],
//     }
//     `,
//     "parameters": `

//             {"question: Given the following:

//             Date of Birth: ${data?.birthDate}
//             Sex: ${data?.sex}
//             Weight: ${data?.weight}
//             Height: ${data?.height}
//             Diet: ${data?.diet}
//             Physical Activity: ${data?.active}
//             Hours Sitting Per Day: ${data?.sitting}
//             Alcohol Rate: ${data?.alcohol}
//             Smoking: ${data?.smoke} (${data?.smokingLength})
//             Sleep Per Day: ${data?.sleepLength}
//             Overall Health Rating: ${data?.overallHealth}
        
//             Calculate my rate of aging ?

//             Ensure to respond with the output option on the initial condition.
//             I know you don't have enough data but use your best understanding.
//             Respond with either Reverse, Fast, Moderate, or Slow. Remember as a json object.
//             "}
//         `}


//     const content = new Blob([prompt], { type: "application/json" });
//     const fileObj = new File([content], "file.json", {
//         type: "application/json",
//     });
//     const res = await client.put([fileObj]);
//     console.log(res);
//     return res;
// }