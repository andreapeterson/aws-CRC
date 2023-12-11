const counter = document.querySelector(".counter-number"); //selects this element from the index.html file
async function updateCounter() {
    let response = await fetch("https://mgkp5gmdeq2zh2vd6kntspfjn40tdtvo.lambda-url.us-east-1.on.aws/");
    let data = await response.json();
    counter.innerHTML = `Website View Count: ${data}`;
} //this function does a fetch request to the function url and then stores it as a variable named data. then it updates counter-number in the index.html to say the views
updateCounter();