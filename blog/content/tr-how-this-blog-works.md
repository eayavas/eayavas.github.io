---
title: How This Blog Works
date: 2025-12-07
lang: TR
---

##  Bu Blog Nasıl Çalışıyor?
Web siteme bir blog bölümü eklemeye karar verdiğimde, ana sayfalarımın minimalist yapısını koruyacak ve genel mimariyi basit tutacak bir yönteme ihtiyacım vardı. Elbette, her gönderi için ayrı HTML dosyaları manuel olarak oluşturabilirdim. Ancak bu yaklaşım, içerik oluşturma açısından zahmetliydi ve esneklikten yoksundu ve tüm gönderilerde tek bir ortak öğeyi değiştirmek, her sayfayı ayrı ayrı yeniden düzenlemeyi gerektirirdi.

Statik siteler için pratik yöntemler araştırdıktan sonra Jekyll veya Hugo gibi ağır ve gereksiz statik site oluşturucuları kullanmak istemedim. Bunun yerine, calışma mantığını aşağıdaki tabloda görebileceğiz, Markdown formatında yazılmış blog yazılarını otomatik olarak html sayfasına çevirerek web dizinine ve blog indexine ekleyen bir [Bash scripti](/blog/build.sh) yazmayı tercih ettim.

![Script Scheme](assets/buildShFlow.jpg)

Bu scriptin çalışabilmesi için web sayfamın dizin yapısını aşağıdaki gibi oluşturdum:

    root
    ├── blog
    │   ├── assets
    │   │   └── buıldShFlow.jpg
    │   ├── build.sh
    │   ├── content
    │   │   └── en-how-this-blog-works.md
    │   └── templates
    │       ├── index.html
    │       └── post.html
    ├── CNAME
    ├── contact.html
    ├── css
    │   └── style.css
    ├── index.html
    ├── public
    │   └── blog
    │       ├── en-how-this-blog-works.html
    │       └── index.html
    └── setup.html

Kısaca script öncelikle Markdown dosyasının ilk satırlarında yer alan ad, tarih ve dil bilgilerini içeren kısmı parse ediyor. (Bu işlem için Linux da cok sık kullandığım **sed** komutu  MacOS da beklediğim gibi çalışmadığı için hem MacOS hem Linux üzerinde çalışabilmesi için bu parse işlemini, daha geleneksel bir yöntemle, **grep** ile yapmam gerekti.) Sonrasında Markdown dosyasının içeriğini, blog sayfasının genel yapısını gösteren, önceden oluşturmuş olduğum template dosyalarına göre **pandoc** aracına ilk parse ettiğim dosya bilgilerine göre bir HTML dosyası oluşturtuyorum. Bu sayede Markdown formatındaki dosya public dizini altında HTML formatına çevrilmiş ve yayınlanmış oluyor.

    files=("$CONTENT_DIR"/*.md)
    if [ ${#files[@]} -eq  0 ]; then
    echo  "Warning: There is no .md file in 'content' folder!"
    
    else
   		for  file  in  "${files[@]}"; do
	   		filename=$(basename  --  "$file")
	   		slug="${filename%.*}"
	   
	   		title=$(grep  "^title:"  "$file"  |  sed  's/title: //g'  |  tr  -d  '"'  |  tr  -d  '\r')
	   		date=$(grep  "^date:"  "$file"  |  sed  's/date: //g'  |  tr  -d  '"'  |  tr  -d  '\r')
	   		lang=$(grep  "^lang:"  "$file"  |  sed  's/lang: //g'  |  tr  -d  '"'  |  tr  -d  '\r')
	   		if [ -z  "$lang" ]; then  lang="EN"; fi
	   
	   		echo  " -> Converting: $slug"
	   
	   		pandoc  "$file"  \
		   		-f  markdown  \
	   			-t  html  \
				--template="$TEMPLATE_POST"  \
				--highlight-style=tango  \
				-o  "$OUTPUT_DIR/$slug.html"
	   
	   		echo  "$date|$lang|$title|$slug.html"  >>  "$TEMP_INDEX_DATA"
   		done
    fi

İkinci aşamada ise oluşturduğumuz web sitesini blog index listesine yani public altındaki blog/index.html dosyasına eklememiz gerekiyor. Bu işlem için html injection metodunu kullanıyoruz. Script daha önceden oluşturmuş olduğum blog sayfasının index.html template dosyasını satır satır okuyarak template dosyası içinde özel anahtarlar kelimelerle belirtilmiş alanlara, bul ve yerleştir işlemi gerçekleştiriyor. 

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


Bu sayede hem Markdown düzenlemenin avantajlarından faydalanıyoruz. Hem de template dosyaları sayesinde tüm blog dosyalarında geçerli olacak bir değişiklik yapmak istediğimizde  tüm sayfaları tekrar yeni şablona göre script ile çevirerek pratik bir şekilde güncelleyebiliyoruz.
