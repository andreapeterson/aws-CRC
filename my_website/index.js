const counter = document.querySelector(".counter-number"); //selects this element from the index.html file
async function updateCounter() {
    let response = await fetch("https://mgkp5gmdeq2zh2vd6kntspfjn40tdtvo.lambda-url.us-east-1.on.aws/");
    let data = await response.json();
    counter.innerHTML = `Website View Count: ${data}`;
} //this function does a fetch request to the function url and then stores it as a variable named data. then it updates counter-number in the index.html to say the views
updateCounter();




const apiUrl = 'https://andrea-strava-api-4730c4f3ed9b.herokuapp.com/strava-metrics';

async function updateMetrics() {
  try {
    const response = await fetch(apiUrl);
    if (!response.ok) throw new Error('Network response was not ok');
    const data = await response.json();

    document.getElementById('milesRan').textContent = data.milesRan ?? 0;
    document.getElementById('milesWalked').textContent = data.milesWalked ?? 0;
    document.getElementById('totalActivityMinutes').textContent = data.totalActivityMinutes ?? 0;
    document.getElementById('elevationGain').textContent = data.elevationGain ?? 0;
  } catch (error) {
    console.error('Error fetching metrics:', error);
  }
}

window.addEventListener('DOMContentLoaded', updateMetrics);





