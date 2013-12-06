# Very Ornate Code

So [Literate Coffeescript](http://coffeescript.org/#literate) is a cool idea,
but why isn't there a standard JS or compile-to-JS version?  JS Programmers want
some love too!  This is my effort to rectify this inequity.

```json>package.json
{
  "version": "0.4.0",
```

## How to use this

To use in-browser, include the marked source (and optionally the coffee-script 
source if needed):

```html>
<script src="https://raw.github.com/chjj/marked/master/lib/marked.js"></script>
<script src="http://coffeescript.org/extras/coffee-script.js"></script>
```

This exposes a VOC object.  See the complete example in `scriptify.js.md`. 


On the command line `voc.njs` will install as `voc` if done globally:

```json>package.json
  "bin": {
    "voc": "./voc.njs"
  },
```

`voc` will read JS/coffee.  The command itself is pretty straightforward:

```js>voc.njs
#!/usr/bin/env node

var myfile = process.argv[2]; if(!myfile || myfile ==='-') myfile='/dev/stdin';
var data = require('fs').readFileSync(myfile,'utf8');
var d = require('./voc').run(data);
var fs = require('fs');
```

If the `.vocrc` file exists, read it and parse for JSON:

```
if(fs.existsSync('.vocrc')) {
  var vocrc = JSON.parse(fs.readFileSync('.vocrc','utf8'));
```

The main output file is specified in the `output` key (this is useful for files
that can be used in the browser):

```
  if(vocrc.output) fs.writeFileSync(vocrc.output, d);
```

If a `post` key is specified, run the command:

```
  if(vocrc.post) {
    var exec = require('child_process').exec;
    var make = exec(vocrc.post);
  }
}
```

If `.vocrc` is missing, just run and print the main output to stdout: 

```
else console.log(d);
```

## Additional Features

If language includes a redirect `>`, the command-line utility will attempt to 
redirect the contents to the file named after the `>` -- no spaces allowed.  The
browser version will silently ignore them.  _By omitting a filename, the block
will be hidden._

In redirects, the file will be compiled incrementally if the file extension is
`.js` but will be preserved if the extension is not `.js`.  

If no language is specified, the last file behavior is inherited.  

The following code block will be emitted as coffeescript

```coffee>tmp/testvoc.coffee
# This will be written to testvoc.coffee as coffeescript
myfile = process.argv[2]
myfile = "/dev/stdin"  if not myfile or myfile is "-"
data = require("fs").readFileSync(myfile, "utf8")
console.log require("./voc").run(data)
```

However, by changing the extension to `.js`, VOC will try to compile:

```coffee>tmp/testvoc.js
# This will be written to testvoc.coffee as coffeescript
myfile = process.argv[2]
myfile = "/dev/stdin"  if not myfile or myfile is "-"
data = require("fs").readFileSync(myfile, "utf8")
console.log require("./voc").run(data)
```

However, even if you put an extension `.js`, not including a language will pass
the file as raw:

```>tmp/badtest.js
# You may think this is coffeescript, but VOC can't possibly know
console.log "this", "will", "fail"
```

And for good measure, to be sure we don't accidentally commit those files, the 
`.gitignore` file can be refreshed:

```>.gitignore
tmp/
```

## Extending

As described in the code below, there are two exported methods: `add` and `run`.
To add your own language:

1. Define the handler function (accepts code and returns JS)

2. Add the language to the framework

3. Profit!

In the code below, both JS and coffee are added.

The `scriptify.js.md` file in this repo shows how coffee and JS can be mixed.


## The Code

Running `voc` against this code should produce the `voc.js` source.  Try it!

```bash>
diff <(voc voc.md) voc.js
```


Header comes first:

```js
var VOC = {};
(function(exports){
```

`handlers` will store all of the handlers: 

```
  var handlers = {};
```

The `add` function takes two parameters: a language type and a handler.  If the type is an array, then each string will be a key.  The `>` character works as
described above.

```
  var add = function(lang, handler) {
    if(typeof lang === "string") handlers[lang] = handler; 
    else lang.forEach(function(l) { handlers[l] = handler; });
  };
```

`files` will keep track of all of the files that have been touched.  Because a
file may be referenced in multiple discontiguous blocks, and since the file is
written as the process continues, the first action must be a write and the 
others must be appends.

```
  var files = {};
```

To satiate the node gods, we must include `mkdirp` to support arbitrary file
locations (writing to `'foo/bar'` will fail unless `foo` exists):

```
  var fs = typeof require === "undefined" ? false : require('fs');
  var mkdirp = !fs ? false : function(f) { return require('mkdirp').sync(require('path').dirname(f)); };
```

The default behavior is to "carry" the last language if one is omitted.  As seen
above, the `js` language tag was not applied to the last few code blocks, so the
engine automatically assumes they are the same as the last known language (in 
this case, the `js` from the header block).  The blocks are concatenated until a
block in a different language is found, and only then will it send the entire 
mess through the handler.

```
  var lastlang="js";
  var process_code = function(src, lastlang) {
```

First we check if a redirect is present:

```
    var offset = lastlang.indexOf(">");
    if(offset !== -1) {
      var f = lastlang.substr(1+offset);
      var lang = lastlang.substr(0,offset);
```

If no file is specified or if we are in the browser, don't do anything:

```
      if(!f || !fs) return "";
```

If the file is specified with extension `'.js'`, process the source (otherwise
leave the source untouched):

```
      var s = src + "\n";
      if(f.substr(-3) === '.js') s = process_code(s, lang);
```

This is a quick patch for Makefiles (because the tabs need to be replaced with
spaces -- markdown mandates that \t -> '    '):

```
      if(lang === 'make') s = process_code(s, lang);
```

Now we can write or append to the file:

```
      if(mkdirp) mkdirp(f);
      if(files[f]) fs.appendFileSync(f, s);
      else { files[f] = 1; fs.writeFileSync(f, s); }
      return "";
    }
```

If there is no redirect (or if the function is being called by the case above),
then we apply the appropriate handler:

```
    else if(!lastlang) return src;
    else if(!(lastlang in handlers)) throw "Unrecognized language " + lastlang;
    return handlers[lastlang](src);
  };
```

The `run` function takes one parameter: the source code

```
  var run = function(src) {
```

It will first use [marked](https://npmjs.org/package/marked)'s excellent lexer
to extract the code blocks:

```
    var M = (typeof marked !== "undefined" ? marked : require('marked'));
    var data = M.lexer(src).filter(function(y) { return y.type === 'code'; });
```

Then it will iterate through each code block (`var t` will store the final `js`
code and `var s` will hold the code blocks that should be concatenated).  For
each code block:

If the language is specified, it differs from the last known language, and there
is code to be processed, it will combine and try to process it. Otherwise, push
it onto the list of code blocks in the current language:

```
    var t = [], s = [];
    data.forEach(function(x) {
      if(x.lang) {
        if(x.lang !== lastlang && s.length > 0) {
          var c = process_code(s.join("\n"), lastlang);
          if(c) t.push(c);
          s = [];
        }
        lastlang = x.lang; 
      } else x.lang = lastlang;
      s.push(x.text);
    });
```

Finally, process the last set of code blocks and return the final JS output:

```
    t.push(process_code(s.join("\n"), lastlang));
    return t.join("\n");
  };
```

Export those functions:

```
  exports.add = add;
  exports.run = run;
```

Add the `js` and `coffee` standard languages:

```
  add(["js","javascript"], function(code) { return code; });
  add(["coffee","coffee-script"], function(code) {
    var CS = (typeof CoffeeScript !== "undefined") ? CoffeeScript : require('coffee-script');
    return CS.compile(code, {bare:true});
  });
```

The Makefile magic is needed because `marked` doesnt preserve the tab character
and because I use it frequently enough to justify special handling:

```
  add(["make","Makefile"], function(code) { return code.replace(/^        /g,"\t").replace(/\n        /mg,"\n\t"); }); 
```

Standard Footer

```
})(typeof exports !== "undefined" ? exports : VOC);
```

And we are done!

Now for some other required fields to finish the `package.json` file:

```json>package.json
  "name": "voc",
  "author": "SheetJS",
  "description": "Generalized Literate Programming Framework",
  "keywords": ["literate", "programming", "voc", "javascript"],
  "main": "voc.js",
  "dependencies": {
    "marked":"",
    "mkdirp":""
  },
  "devDependencies": {
    "coffee-script":""
  },
  "repository": { "type": "git", "url": "git://github.com/SheetJS/voc.git" },
  "bugs": { "url": "https://github.com/SheetJS/voc/issues" },
  "preferGlobal": true
}
```

And of course, how could I forget the venerable Makefile:

```make>Makefile
LIBRARY=voc

$(LIBRARY).js: voc.md
        ./voc.njs $^ > $@2
        mkdir -p old/
        cp $@ old/$@
        mv $@2 $@ 
```

Those files should be ignored by both git and npm:

```>.gitignore
old/
node_modules/
```


```>.npmignore
tmp/
old/
```


## Warning

Be extra careful: some of these commands replace data without warning!
