#!/bin/bash

TEMPLATE_POST="templates/post.html"
TEMPLATE_INDEX="templates/index.html"
CONTENT_DIR="content"
OUTPUT_DIR="../public/blog"
TEMP_INDEX_DATA="temp_index_data.txt"

mkdir -p "$OUTPUT_DIR"
rm -f "$TEMP_INDEX_DATA"

echo "Building blog..."

shopt -s nullglob
files=("$CONTENT_DIR"/*.md)

if [ ${#files[@]} -eq 0 ]; then
    echo "Warning: There is no .md file in 'content' folder!"
else
    for file in "${files[@]}"; do
        filename=$(basename -- "$file")
        slug="${filename%.*}"
        
        title=$(grep "^title:" "$file" | sed 's/title: //g' | tr -d '"' | tr -d '\r')
        date=$(grep "^date:" "$file" | sed 's/date: //g' | tr -d '"' | tr -d '\r')
        lang=$(grep "^lang:" "$file" | sed 's/lang: //g' | tr -d '"' | tr -d '\r')
        if [ -z "$lang" ]; then lang="EN"; fi

        echo "   -> Converting: $slug"

        pandoc "$file" \
            -f markdown \
            -t html \
            --template="$TEMPLATE_POST" \
            --highlight-style=tango \
            -o "$OUTPUT_DIR/$slug.html"

        echo "$date|$lang|$title|$slug.html" >> "$TEMP_INDEX_DATA"
    done
fi

echo "Generating index page..."

posts_html=""

if [ -f "$TEMP_INDEX_DATA" ]; then
    sorted_posts=$(sort -r "$TEMP_INDEX_DATA")
    
    while IFS='|' read -r date lang title url; do
        posts_html+="<div class='grid-list'><div class='grid-label'>$date [$lang]</div><div><a href='$url'>$title</a></div></div>"
        posts_html+=$'\n' 
    done <<< "$sorted_posts"
else
    posts_html="<p>No posts found yet.</p>"
fi

while IFS= read -r line; do
    if [[ "$line" == *"\$post_list\$"* ]]; then
        echo "$posts_html"
    else
        echo "$line"
    fi
done < "$TEMPLATE_INDEX" > "$OUTPUT_DIR/index.html"

rm -f "$TEMP_INDEX_DATA"

echo "Copying assets..."
mkdir -p "$OUTPUT_DIR/assets"
cp -r assets/* "$OUTPUT_DIR/assets/" 2>/dev/null || :

echo "Build complete! Check public/blog/index.html"
