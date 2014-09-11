---
title: Haskell and Bash, basically interchangeable
subblog: tech
tags: haskell
---

It's not often you get to spend way longer than warranted on a grand rewrite.

I had a dumb little bash script for starting new blog posts. It would do a couple of things:

- read in the title of a post
- reformat that title for a filename, prefixed with the current date
- create the file for the post along with relevant metadata

There's a little more but that's most of it. Here it is in all of its typical shell horribleness:

```bash
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
```

I wanted to add a couple of minor features but they seemed like way more trouble than is ever warranted in Bash. I decided to rewrite it in another language. I could have chosen my old buddy Perl, seemingly a perfect fit for text manipulation and shelling out and so forth. But Perl didn't catch my imagination on a long flight without wifi. Haskell did. So that's what I used.

<!-- MORE -->

### Coding on a Plane

I generally think writing software without a good Internet connection is impossible. In this case however I knew only standard Haskell libraries should suffice. I shouldn't need a library from the sky or any documentation, or at any rate doing it without documentation was the challenge. While I was sort of rusty on Haskell syntax and particular functions, I did have `ghci` on my side. I could explore modules with tab completion and by asking for the types of things. Pressing through artificial constraints can be fun!

### The bad

The bash script was 20 lines. The haskell program is 85. Take out comments, blank lines, and type hints and the Haskell sneaks under 50 lines. That's not horrible considering it does a little more and it's easier to extend, but it's definitely not a great result. I bet Perl is significantly shorter while still being full-featured (great, now I have to remember how to write Perl and do this exercise again). 

It was no surprise that by far the hardest thing to figure out was reading the system date into a string. I spent a long time exploring the module `System.Process` trying to figure out how to shell out and read standard output of the subprocess into a string. Doubtless the Internet would have made this faster, but as I expected the way to do this was buried under many layers of Haskell knowing What I Was Really Asking For and modeling it properly in with its language constructs. Darned if I was going to figure it out. I was lucky enough to find the function `Data.Time.Clock.getCurrentTime` which is of type `IO UTCTime`. I then had to figure out where in the world the `show UTCTime` instance was buried so that I could get from `UTCTime` to `String`. I got there eventually but it wasn't exactly edifying. 

### The Good

In general I like Knowing What I'm Really Asking For. For instance I modeled the allowed characters for blog post titles and filenames both as sets of characters, because that's what they are! Even though the syntax isn't as concise as shell globbing, it was far more precise, and I liked the gain in declarativeness.

On a related note, functional programming is really fun. Most of my functions are expressed through function composition, partial application of common idioms, and monad-fu. Living in a higher level of abstraction makes extending and improving the program easy and fast. Once I had replicated the functionality of the bash script, the new features I wanted were trivial to add.

One of the best parts has got to be the way `main` turned out. You don't need to have ever read Haskell, or code really, to understand what the program does. Check it out:

```haskell
main :: IO ()
main = do
  dateStr  <- dateAsString
  postName <- getPostNameFromUser
  subblog  <- getSubblogFromUser
  let filename = dateAndPostNameToFileName dateStr postName
  let path = "content/posts/" ++ filename
  let info = InfoForPost postName subblog
  writeFile path (postBody info)
  putStrLn "Happy writing."
```

You can find the full file on GitHub.

### A puzzler

I developed the program using `ghci` and `runghc`. `runghc` is how I execute it because then it's just like an interpreted language and that seemed the right spirit for the problem. Well, when I actually compile the code, the executable doesn't behave quite right. The timing of the prompts to the user is all off.

I'm not sure what the deal is there. Maybe I'll look into it sometime.

### It was worth it.

Overall I'm glad I did this. It sure occupied me on my flight. It was also interesting to use Haskell for a problem for which it would traditionally be considered weak. Even this shell script rewrite was super fun to apply Haskell's type system and functional features to.

I wonder what other Bash is begging to be rewritten.
