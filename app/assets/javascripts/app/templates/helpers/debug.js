define(['handlebars'], function(Handlebars) {
  function debug(optionalValue) {
    console.log("Current Context");
    console.log("====================");
    console.log(this);
    if (optionalValue) {
      console.log("Value");
      console.log("====================");
      console.log(optionalValue);
    }
  }
  Handlebars.registerHelper('debug', debug);
  return debug;
});

