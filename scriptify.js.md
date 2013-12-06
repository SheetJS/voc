# Scriptify.js -- Browser plumbing for your custom language

So you've got this kick-ass compile-to-JS language, and you've put together a 
[Jison parser](http://zaach.github.com/jison/) and now you want to start writing
webpages with it.  But you don't just want to call a compiler and push JS.  You
just want to write code with your own script tags. 

This is a problem many people have encountered: 
 - [CoffeeScript](http://coffeescript.org) has its own magic
 - [Brython](http://brython.info/index_en.html) has its own way
 - Many a person have tried to implement Brainfuck in JS

But there seems to be no standard way to approach the problem.

Enter scriptify.js:

```html>
<script type="text/mylang">
... here's some code in your awesome programming language ...
</script>
```

## Usage

1. Set up your handler functions.  They are expected to take the source as an
argument and return the javascript source.  For example, to just eval source:

```js>
function clog(x) { (typeof console !== 'undefined' && console.log) ? console.log(x) : alert(x); };
var eval_handler = function(x) { clog(eval(x)); };
```

2. Call `scriptify.add` to instruct Scriptify to use your handler.  The function
takes a `tag` and a handler function:

```js>
scriptify.add("mylang", handler);
scriptify.add("eval", eval_handler);
```

3. Write your code in your language:

Code embedded in the HTML `<script>` tag should have the `type` attribute set 
to `text/..tag..` or `application/..tag..`:

    <script type="application/eval">
    1+1
    </script>
    <script type="text/mylang">
    ... this is the fun part where you start writing code in your language ...
    </script>

When referencing external scripts, make sure to set the `type` attribute:

    <script type="text/eval" src="my_script.eval"></script>
    <script type="application/mylang" src="some_file.myl"></script>

4. Run it!

```js>
scriptify.run(); // will run on every script tag (file and src)
```

Of course, if you want to run a small code chunk (think `eval` for your lang):

```
scriptify.run("mylang", "code_in_my_lang"); // run the code
```


# Source Code

This is it! [Very Ornate Code](https://github.com/SheetJS/voc) can process this 
GFMarkdown document, extracting relevant code segments.  Blocks with languages 
ending in `>`, like all of the blocks above, are ignored.

I like JSHint, but some warnings aren't necessary, so let's suppress them first:

```js
/*jshint es5:true, evil:true, boss:true */
```

Standard closure setup (hiding some utility functions, as we'll see in a moment)

    var scriptify = (function scriptify() {

## Browser Plumbing

The first function is *getext*, which gets the text of a DOM node.  Given my
lack of experience and general disgust with coffeescript, I figured this is so
small that I could just try it out here:

```coffee

```

      getext = (node) ->
        node.innerText or node.textContent or node.text

The next function does the actual injection (given the javascript code and the
original script node).   

      __e = (code, node) ->

First create the new node:

        loc = document.createElement("script")
        n = document.createTextNode(code)

Then try to add the node (replacing the text if it is not possible):

        try
          loc.appendChild n
        catch e
          loc.text = code

If we don't know where the source came from, just add to the end of the file.  
Otherwise replace the old node with the new one:

        unless node
          document.body.appendChild loc
        else
          node.parentNode.replaceChild loc, node


## Handling Handlers

As it is currently laid out, only one handler per type is supported:

      handlers = {};
      @add = (type, action) ->
        handlers[type] = action


## The Actual Run Function

This is the actual run function:

```js

```

The reason I don't insert code in the fenced area is because it looks weird to
mix the two (it looks really weird)

      this.run = function(type, sr) {

One deficiency of the compiler is that you can't mix-and-match at the function 
level: the coffeescript compiler insists on making that end curly brace, and it 
is far easier and safer to just let it do that.  We can still mix statements,
but we have to use the JS control structure (you can't get coffee to emit a bare
return statement).

So first we check if the function was called with a string argument.  If so, run
it directly (the execScript is for IE):

        if(typeof sr === "string") return (window.execScript||window.eval)(handlers[type](sr));

Otherwise we need to iterate through the document:

        if(typeof document !== 'undefined') {

Find and iterate through all of the script tags:

```coffee

```

          elts = document.getElementsByTagName("script")

```js

```

          for(var y = 0; y != elts.length; ++y) {

Let's first make sure we can handle the script type:

            var action = (handlers[elts[y].type] || handlers[elts[y].type.split("/")[1]]);
            if(!action) continue; 

If the `src` attribute is specified, we need to do an XHR to get the content:

            if(elts[y].src) {

```coffee

```
          
              XHR = (if window.XMLHttpRequest then new XMLHttpRequest() else new ActiveXObject("Microsoft.XMLHTTP"))
              XHR.open "GET", elts[y].src, false
              XHR.send()
              throw "XHR Error " + XHR.status  unless XHR.status is 200

Once we have the data, we can 

```js

```

              __e(action(XHR.responseText), elts[y]);
            } else {
              __e(action(getext(elts[y])), elts[y]);
            }
          }

Remember when I said it looks ugly to mix styles?  Let's take a peek:

```js
    }
  };
```

Then we end the code:


      return this;
    })();

And that's all, folks!

# Complete Example

This example runs VOC on the Markdown files and prints the output:

```html>
View the console to see output
<script src="http://coffeescript.org/extras/coffee-script.js"></script>
<script src="https://raw.github.com/chjj/marked/master/lib/marked.js"></script>
<script src="scriptify.js"></script>
<script src="voc.js"></script>
<script type="text/md" src="scriptify.js.md"></script>
<script>
	function clog(x) { console.log(x) };
	scriptify.add("md", function(x) { clog(VOC.run(x)); });
	scriptify.run();
</script>
```

This was the example on [the website](http://sheetjs.github.com/scriptify.js).
It looks a bit spartan, but it does show functionality on IE6!

```html>
View the console to see output
<script type="text/console">
Print this to console
</script>
<script type="application/eval">
1+1
</script>
<script type="text/eval" src="sample"></script>
<script type="text/console" src="sample"></script>
<script src="scriptify.js"></script>
<script>
  function clog(x) { (typeof console !== 'undefined' && console.log) ? console.log(x) : alert(x); };
  scriptify.add("eval", function(x) { clog(eval(x)); });
  scriptify.add("console", function(x) { clog(x); });
  scriptify.run();
  scriptify.run("eval", "Math.pow(2,3)");
  scriptify.run("console", "Math.pow(2,3)");
</script>
```
