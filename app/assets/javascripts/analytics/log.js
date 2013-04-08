if(!window.console) {
  console = {
    log : function(){},
    info : function(){}
  }
}

window.analytics = {

  init: function(){
    console.log('Analytics.init');
    console.log(arguments)
  },
  track: function() {
    console.info('Analytics.track'); 
    console.info(arguments); 
  },
  trackLink: function() {
    console.info('Analytics.trackLink');
    console.info(arguments); 
  },
  trackForm: function() {
    console.info('Analytics.trackForm');
    console.info(arguments); 
  },
  trackPageView: function() {
    console.info('Analytics.trackPageView');
    console.info(arguments); 
  },
  identify: function() {
    console.info('Analytics.identify');
    console.info(arguments); 
  },
  alias: function() {
    console.info('Analytics.alias');
    console.info(arguments); 
  },
  set: function() {
    console.info('Analytics.set');
    console.info(arguments); 
  },
  increment: function() {
    console.info('Analytics.increment');
    console.info(arguments); 
  },
  trackCharge: function() {
    console.info('Analytics.trackCharge');
    console.info(arguments); 
  }
}
