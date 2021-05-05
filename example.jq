#!/usr/bin/env -S jq -rnMf
import "./html" as H {};
import "./star-wars-lego-sets" as $sets {};

# convenience functions for tr, td, table, img nodegen
def tr(attrs; filter):    H::node("tr";    attrs; filter);
def td(attrs; filter):    H::node("td";    attrs; filter);
def img(attrs; filter):   H::node("img";   attrs; filter);
def table(attrs; filter): H::node("table"; attrs; filter);

def lego_set_to_row:
    tr({};
        td({}; .name),
        td({}; .number),
        td({}; .rating),
        td({}; .LEGOCom.US.retailPrice),
        td({}; img({ src: .image.imageURL }; empty))
    )
    ;

def name_like($regex): select(.name | test($regex; "i"));

def best_xwings:
    $sets | .[0]               # Get all the sets
  | map(name_like("x-wing"))   # Filter to x-wings
  | sort_by(.rating) | reverse # Find the best x-wings
    ;

table({}; best_xwings | .[] | lego_set_to_row)
| H::render
