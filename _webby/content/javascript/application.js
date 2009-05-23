$(document).ready(function(){
  $("#twitter").getTwitter({
    userName: "leshill",
    numTweets: 5,
    loaderText: "Loading tweets...",
    slideIn: true,
    showHeading: true,
    headingText: "Latest Tweets",
    showProfileLink: false
  });
});
