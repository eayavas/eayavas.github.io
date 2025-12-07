#!/bin/bash

TEMPLATE_POST="templates/post.html"
TEMPLATE_INDEX="templates/index.html"
CONTENT_DIR="content"
OUTPUT_DIR="../public/blog"
TEMP_INDEX_DATA="temp_index_data.txt"

mkdir -p "$OUTPUT_DIR"
rm -f "$TEMP_INDEX_DATA"

echo "Building blog..."

# 1. Markdown -> HTML
for file in "$CONTENT_DIR"/*.md; do
    filename=$(basename -- "$file")
    slug="${filename%.*}"
    
    title=$(grep "^title:" "$file" | sed 's/title: //g' | tr -d '"' | tr -d '\r')
    date=$(grep "^date:" "$file" | sed 's/date: //g' | tr -d '"' | tr -d '\r')
    lang=$(grep "^lang:" "$file" | sed 's/lang: //g' | tr -d '"' | tr -d '\r')
    if [ -z "$lang" ]; then lang="EN"; fi

    echo "Converting: $slug"

    pandoc "$file" \
        -f markdown \
        -t html \
        --template="$TEMPLATE_POST" \
        --highlight-style=tango \
        -o "$OUTPUT_DIR/$slug.html"

    echo "$date|$lang|$title|$slug.html" >> "$TEMP_INDEX_DATA"
done

echo "Generating index..."
sorted_posts=$(sort -r "$TEMP_INDEX_DATA")
posts_html=""

while IFS='|' read -r date lang title url; do
    # DİKKAT: MacOS uyumluluğu için satır sonuna \n KOYMUYORUZ.
    item="<div class='grid-list'><div class='grid-label'>$date [$lang]</div><div><a href='$url'>$title</a></div></div>"
    posts_html+="$item"
done <<< "$sorted_posts"

sed "s|\$post_list\$|$posts_html|g" "$TEMPLATE_INDEX" > "$OUTPUT_DIR/index.html"

rm "$TEMP_INDEX_DATA"
echo "Done."
