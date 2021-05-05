# html.jq

A simple (&lt;40 line) library to simplify generating HTML from JSON using the
JQ programming language.

## Basic Usage

Say I have an input record in JSON about a person which I want to convert to a
row in an HTML table:

```json
{
    "fname": "Daisy",
    "lname": "Steiner",
    "age": 58
}
```

A JQ program to do this very quickly would be:

```jq
"<tr>
    <td>\(.fname)</td>
    <td>\(.lname)</td>
    <td>\(.age)</td>
</tr>"
```

`html.jq` helps with this process by providing a schema for defining HTML in
JSON and function `render` to turn that schema into HTML. Rewriting the above
to use `html.jq`:

```jq
import "./html" as H {};

H::node("tr"; {}; # table row, no attributes
    H::node("td"; {}; .fname),
    H::node("td"; {}; .lname),
    H::node("td"; {}; .age)
)
| H::render
```

Here, a call to `H::node(<tag>; <attrs>; <children>)` creates an HTML node with
the appropriate tag `<tag>`, attributes `<attrs>`, and children `<children>`.
The final pipe to `H::render` renders the created object tree into HTML as a
string.

That may look like a mouthful on this simple example, and it is. For such an
example, in a small one-off script, I would go with the first option.

But when you begin to generate deeper HTML trees with composed components, in
scripts that may need to be read later, a library with a schema and final
rendering step begins to be more useful.

### Indentation

Extend the problem: now we have an array of person records, and we want to
generate the whole table for this list of people:

```json
[
    {
        "fname": "Daisy",
        "lname": "Steiner",
        "age": 58
    },
    {
        "fname": "Tim",
        "lname": "Beasley",
        "age": 61
    }
]
```

Reusing our previous code, and sticking purely to string interpolation, we can
do this:

```jq
def person_to_row:
    "<tr>
        <td>\(.fname)</td>
        <td>\(.lname)</td>
        <td>\(.age)</td>
    </tr>";

"<div>
    This is our list of people:
    <table>
        \(map(person_to_row) | join("\n"))
    <table>
</div>"
```

This works, but the indentation of each row for a person is hardcoded: the
first line gets no indentation, the next three are double-indented, and the
last is single-indented. This means whenever we interpolate it into larger
pieces of HTML, we are more likely than not going to get something messy.

For example, the code above produces:

```html
<div>
    This is our list of people:
    <table>
        <tr>
        <td>Daisy</td>
        <td>Steiner</td>
        <td>58</td>
    </tr>
<tr>
        <td>Tim</td>
        <td>Beasley</td>
        <td>61</td>
    </tr>
    <table>
</div>
```

On the other hand, `html.jq`'s `node` function generates a JSON tree, where
each node is an object with a tag, a dict of attrs, and an array of children.
Text nodes are just represented as strings.

For example, the html fragment `<img src="./my-cool-photo.png">Cool!</img>`
would be generated as:

```json
{
    "tag": "img",
    "attrs": {
        "src": "./my-cool-photo.png"
    },
    "children": [
        "Cool!"
    ]
}
```

The `node` function is essentially just a very thin wrapper for generating
these objects.

Once the final tree is created, `render` then walks the tree and children,
rendering and indenting correctly.

So, to reimplement our table script using `html.jq`:

```jq
import "./html" as H {};

def person_to_row:
    H::node("tr"; {};
        H::node("td"; {}; .fname),
        H::node("td"; {}; .lname),
        H::node("td"; {}; .age)
    )
    ;

H::node("div"; {};
    "This is our list of people:",
    H::node("table"; {};
        .[] | person_to_row
    )
)
| H::render
```

Which outputs HTML with correct indenting (though possibly too many newlines):

```html
<div>
  This is our list of people:
  <table>
    <tr>
      <td>
        Daisy
      </td>
      <td>
        Steiner
      </td>
      <td>
        58
      </td>
    </tr>
    <tr>
      <td>
        Tim
      </td>
      <td>
        Beasley
      </td>
      <td>
        61
      </td>
    </tr>
  </table>
</div>
```

Furthermore, with the HTML being a dictionary, we can observe and transform its
structure before passing it along to `render`, so we could have some final
postprocessing steps if we want them.

## A Longer Example

Now that we have HTML generation in JQ, we can query large JSON dumps from APIs
and produce simple visualizations in no time!

Take this May the Fourth script: Given a large JSON blob of LEGO Star Wars
sets, we can quickly find all of the X-Wing sets ever made and render them in a
catalogue, with prices and ratings!

```jq
#!/usr/bin/env -S jq -rnMf
import "./html" as H {};
import "./star-wars-lego-sets" as $sets {}; # import the star-wars-lego-sets blob

# convenience functions for tr, td, table, img nodegen
def td(attrs; filter):    H::node("td";    attrs; filter);

def lego_set_to_row:
    H::node("tr"; {};
        td({}; .name),
        td({}; .number),
        td({}; .rating),
        td({}; .LEGOCom.US.retailPrice),
        td({}; H::node("img"; { src: .image.imageURL }))
    )
    ;

def name_like($regex): select(.name | test($regex; "i"));

def best_xwings:
    $sets | .[0]               # Get all the sets
  | map(name_like("x-wing"))   # Filter to x-wings
  | sort_by(.rating) | reverse # Find the best x-wings
    ;

H::node("table"; {}; best_xwings | .[] | lego_set_to_row)
| H::render
```
