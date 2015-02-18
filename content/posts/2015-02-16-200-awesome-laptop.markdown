---
title: $200 awesome laptop
subblog: tech
tags: personal computing
---

My favorite computer ever only cost me $200. It's a repurposed Chromebook.

When I started at [Relay](http://relaynetwork.com) years ago they made me start carrying around this 13 inch MacBook Pro between work and home so that I could always be ready if duty called. At first I resented carrying around this heavy weight on my bike. Eventually I got used to it and I appreciated being able to write email or blog posts on the go. It got to the point that when I announced I was leaving the company in order to travel I felt somewhat urgently the need to replace the machine I would have to return.

This replacement machine would have to be at least as portable as the Mac. It also had to be nice; I had made the mistake before of buying a laptop with the same specs as a Mac under the hood but which had horrible trackpad, screen, battery, and so forth. Finally I wanted it to be cheaper than the $1300 or so my computer would have cost new.

Chromebook to the rescue. I had read about a teaching-kids-how-to-code startup that repurposed $200 Acer C720 Chromebooks into Ubuntu coding environments. They claimed the C720 had the build quality of a machine a three times its price. Sold. But would it work?

<!-- MORE -->

In a word, yes. The C720 is indeed a great little laptop to use; the trackpad works really well, the keyboard is fantastic, and the battery lasts until the cows come home. The 11" screen takes some getting used to but for its purpose I prefer it even to the 13"; it fits in [some pockets](/nick/2015/02/11/love-this-bag.html) the latter would not. And putting ubuntu on it is a cinch.

That's not to say using it doesn't require some tradeoffs, though; they just happen to be tradeoffs I am happy to make.

### RAM

The C720 I bought only comes with 2GB of RAM. That's really not a lot, even running a relatively lightweight operating system. I can compile Java code for my job but the compilers for my favorite languages like Haskell and Scala can't get by on a footprint that small. Even heavy-duty web browsing can cause problems. I've more than once frozen up on Google Maps.

Unfortunately there isn't much you can do about this limitation. The RAM is soldered into the motherboard of the C720 and you can't upgrade it yourself. You can buy a C720 with twice the RAM for about $120 more. In hindsight I think doing so would have been worth it.

### Storage

The point of the Chromebook is to keep you tethered to all of Google's services, including paying for Google Drive cloud storage. For that reason they come with a pitiful amount of storage, a flash drive's worth at 16GB. I got by for about three months on just this much, but I got to a point where I was just completely out of space. Fortunately, this upgrade is pretty easy to do. I bought a 128GB SSD for about $90. Opening up the computer to make the swap only took half an hour or 45 minutes.

So this limitation requries doing a little bit of work to surmount, and a little bit of expense, but overall it's quite manageable.

### A Satellite

That's it, really. There isn't another drawback, and the many advantages have me pleased as punch with this purchase. I'm typing this right now in the tiny room on my lap afforded by Spirit Airlines as I fly to Phoenix on the cheap. It fits in the seatback pocket in front of me.

Altogether though the storage and memory limitations have encouraged me to think of this laptop as a portable satellite orbiting my main compting apparatus. It's not self-sufficient; it's a dispatch. Given the proliferation of computing devices I think this distinction is actually helpful. It's far easier to keep track of in the long run if I have a master-slave relationship to my main personal computing cluster rather than if everything must be an equal peer.

`ssh` enables this relationship in a couple of ways. If I want to code in Scala on this computer, I SSH into my home computer and open up a screen session there. If I want to listen to music, I mount the remote filesystem via `sshfs` and listen to it that way. Port forwarding allows me to run web applications like Mailpile or this blog in my own browser. On the whole it works really well, and it's easier to keep track of where everything is with it all always on one filesystem.

Now to truly replace the cloud by serving up some network-attached storage with a Raspberry Pi...
