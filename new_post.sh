#!/bin/bash

date=$(date +%Y-%m-%d)
need_name=true
while $need_name; do
    read -p "What will you call the blog post? " post
    case $post in
        [A-Za-z0-9\ _\-]* )
          fn=$(echo $post | sed -e 's/ /-/g' | tr A-Z a-z)
          echo "---
title: $post
date: $(date)
tags:
---" > "./content/posts/$date-$fn.markdown"
          echo "Happy writing."
          need_name=false
          ;;
        * ) echo "That's not a knife. Now -this- is a knife!";;
    esac
done
