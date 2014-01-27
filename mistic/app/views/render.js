var fs = require('fs');
var webpage = require('webpage');

var input, output;

input = phantom.args[0];
output = phantom.args[1];

var page = webpage.create();

page.paperSize = { format: 'letter', orientation: 'landscape', border: '1cm' };  

page.open(input, function(status) {
  if (status !== 'success') {
    console.log('Unable to load the input file!');
    phantom.exit();
  } else {
    window.setTimeout(function () {
      page.render(output);
      phantom.exit();
    }, 200);
  }
});
