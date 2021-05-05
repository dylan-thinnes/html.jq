#!/usr/bin/env -S jq -Mf

def node($tag; attrs; children): { tag: $tag, attrs: attrs, children: [children] };
def node($tag; attrs): node($tag; attrs; empty);
def node($tag): node($tag; {}; empty);

def indent: "  " + .;

# Render attributes - object {a: x, b: y} into "a='x' b='y'"
def render_attrs: to_entries | map(" \(.key)='\(.value)'") | join("");

# All the ways to render!
def render:
    # Explicit object node
    (objects |
        "<\(.tag)\(.attrs // {} | render_attrs)>" as $open |
        "</\(.tag)>" as $close |
        if .children | length == 0
        then $open + $close
        else ($open, (.children | .[] | render | indent), $close)
        end
    ),

    # Shorter notation using arrays, converted to object nodes
    (arrays |
        node(.[0]; .[1]; .[2:] | .[]) | render
    ),

    # Scalars can be rendered as strings
    (scalars |
        tostring
    )
    ;
