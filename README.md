#Telegram Bot
A lua script for the Telegram CLI.

###Install
put this script dir inside the ~/.telegram/ .<br>
Change the lua script according to what you need.<br>
Check the config file.<br>

###Usage
The config file is dynamically read everytime a message is received.<br>
Thus, enabling away mode in the config file will directly take effect.<br>
The last line of the config is the away message.<br>
<pre>
	help()            : Display this usage information
	dice()            : Returns a random number 1-6
	quote()           : Returns a random fortune cookie quote
	ping()            : Pong back
	weather()         : Returns the weather status
	md5(string)       : Returns the md5 hash of the string
	sha256(string)    : Returns the sha256 of the string
	define(word)      : Returns the definition of a word
	cleverbot(string) : Ask the cleverbot something
	note(something)   : If away, it will save a note for me
</pre>


###Deps
There are a lot of dependencies due to the main script calling multiple external programs.<br>
<br>
Namely, you'll need:<br>
<pre>
node
(for the 2 node scripts that comes with this repo)
nmh used for notes received as email 
(I read them with sylpheed but you can use any mail client you prefer)
fortune
A file that has the weather in it 
(I'm taken it from another script I wrote to update me about the weather)
curl
A notification script 
(Also comes with this repo, but you can use any other notification system
Note that the notif script depends on bar and beep)
</pre>
