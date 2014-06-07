var urban = require('../lib/urban');

process.argv.forEach( function (val,index, array) {
	if (index >= 2) {
		var word = urban(val);
		word.first(function(json) {
			if (typeof json !== 'undefined') {
				console.log( 
					"Definition:"+json.definition+"\n"+
					"Example:"+json.example
				);
			}
			else {
				console.log("No definition for the word : "+val)
			}
		});
	}
});

