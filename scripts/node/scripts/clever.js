var Cleverbot = require('../lib/cleverbot');
var CBot = new Cleverbot;
callback = function (resp) {
	console.log(resp['message']);
};
process.argv.forEach( function (val,index, array) {
	if (index >= 2) {
		CBot.write(val, callback)
	}
});

