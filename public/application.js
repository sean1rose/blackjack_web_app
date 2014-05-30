$(document).ready(function(){       // upon page load...
  $(document).on("click", "#hit input", function(){ 
    alert("Player Hit AJAX");                                                       
    $.ajax({
      type: "POST",
      url: "/game/player/hit"                         // no additional 'data' {} parameter to submit
    }).done(function(msg){                            // .done-method chained to ajax to handle the response we get back
      $('#game').replaceWith(msg)                     // .done takes anonymous function, which takes msg as parameter; msg is the response object. Response is the game-template response returned form the server                                                    
    });                                                //  -> replacing contents/html of game div/template w/ new content that's returned in msg. WHAT'S RETUNRED IN THE MSG???
    return false;
  });

});

function playerHit() {
  $(document).on("click", "#hit input", function(){ 
    alert("Player Hit AJAX");                                                       
    $.ajax({
      type: "POST",
      url: "/game/player/hit"                         // no additional 'data' {} parameter to submit
    }).done(function(msg){                            // .done-method chained to ajax to handle the response we get back
      $('#game').replaceWith(msg)                     // .done takes anonymous function, which takes msg as parameter; msg is the response object. Response is the game-template response returned form the server                                                    
    });                                                //  -> replacing contents/html of game div/template w/ new content that's returned in msg. WHAT'S RETUNRED IN THE MSG???
    return false;
  });
}

function playerStay() {
  $(document).on("click", "#stay input", function(){
    alert("Player Stay AJAX")
    $.ajax({
      type: "POST",
      url: "/game/player/stay"
    }).done(function(msg){
      $('#game').replaceWith(msg)
    });
    return false;
  });
}

function dealerHit() {
  $(document).on("click", "#dealer input", function(){
    alert("dealer hits");
    $.ajax({
      type: "POST",
      url: "/game/dealer/hit"
    }).done(function(msg){
      $('#game').replaceWith(msg)
    });
    return false;
  });
}

function doubleDown() {
  $(document).on("click", "#double input" function(){
    $.ajax({
      type: "POST",
      url: "/game/player/double"
    }).done(function(msg){
      $('#game').replaceWith(msg)
    });
    return false;
  });
}
