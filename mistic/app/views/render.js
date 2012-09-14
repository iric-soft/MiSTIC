var fs = require('fs');
var webpage = require('webpage');

var input, output;

input = phantom.args[0];
output = phantom.args[1];

var page = webpage.create();

if (phantom.args.length >= 4) {
  page.paperSize = { width: phantom.args[2], height: phantom.args[3] };
}

page.open(input, function(status) {
  if (status !== 'success') {
    console.log('Unable to load the address!');
  } else {
    window.setTimeout(function () {
      page.render(output);
      phantom.exit();
    }, 200);
  }
});
