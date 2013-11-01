---
title: Tech Support Conundrum
date: Thu Oct 31 22:38:24 EDT 2013
tags: Linux, adventures of Nick and Matt
---

### The Problem

The audio jack on my laptop broke, so I had to install a new operating system.

Tech support made me do it. Well, tech support and DRM. I had to get it fixed since I listen to music all of the time when I am computing. If my iphone wasn't such a useless piece of hardware I would be able to transfer FLAC albums to it seamlessly through my Linux Mint installation. But since it is a useless piece of hardware my music was cruelly imprisoned, only able to speak to me through the tinniest of laptop speakers.

So I had to get it fixed. Fortunately the laptop was still under warranty. After the Lenovo guy over the phone was satisfied the broken jack was not caused by software, he asked me to mail it in to the repair center in Texas. That was fine, but there was one catch: they couldn't promise my hard drive wouldn't be wiped in the course of a repair.

Such was an occasion at least for a backup, but I was also worried the repair technician would get spooked by the presence of Linux on my system. What would he do when greeted with a GRUB prompt that would by default take him into not-Windows? Would he say my warranty had been voided by Free Software Poison?

<!-- MORE -->

### Experiment Perilous: The Perfect Crime

I needed to buy a hard drive to hold the backup. It seemed a good opportunity to get a solid-state drive. Maybe I would even permanently switch my 1 terabyte hard disk for the more flashy<sup>1</sup> option. Wait a minute! While I was thinking of swapping drives, I might as well move Windows from my HDD onto the SSD, then install the SSD into the laptop body. That way the tech support guy would be perfectly happy.

As tedious as this all may sound, it sounded like a fun project not just to me but to my good friend Matt. He pledged to join me.

### Linux Fail

Once my SSD came, the two of us set about making a partition table to accomodate the several Windows partitions in my fragmented HDD. We tried a few tools for this, most notably GNU parted, fdisk, and the Linux Mint disk utility. All of them utterly failed in our case. The utilities would complete a couple of operations, then freak out and think there were no entries in the disk's partition table.

What's more, we were led to believe that Windows was not going to like waking up on a disk with different numbers in the partition table (as would be required on a disk of different size), on a drive of a different make than it thought it had been installed on. We moved on to plan B: Instead of installing a Windows-only HDD into my laptop, just hide Linux. Find a way to hide GRUB and to boot into Windows by default. Technician sees no evil, technician does no evil.

Now the SSD was only needed as a backup. But instead of leaving it merely a glorified flash drive, why not make the SSD a working Linux installation? We couldn't see why not.

Shamefully, in the wake of the Linux tools' failure to partition the drive we resorted to using Windows 7 to do the job, and it worked flawlessly. With the help of [this utility](http://www.linuxliveusb.com/) and a flash drive, we had the newest version of Mint running on the SSD in a jiffy.

### A Security Issue

From there it was trivial to copy the 60 GB of files I cared about in my home directory to the SSD. A little too trivial, actually. Who was to say I had permission to copy those files if they weren't marked readable? Well, `sudo` said. But not `sudo` on my original system; `sudo` on the new one. I didn't need root access on the *source* disk to copy from it; I just needed it on the *destination.* That seemed a serious problem to me.

I suppose that is what full-disk encrpytion is for.

### Hiding GRUB

Hiding GRUB was easy. We could have edited the config file directly, but we preferred to use a little GUI utility that we installed through `apt-get`: [grub-customizer](https://launchpad.net/grub-customizer). We only needed to change two settings: `GRUB_DEFAULT` set the default OS to boot into, and `GRUB_TIMEOUT` set how long to wait before booting into that OS. With the default set to Windows and the timeout set to 0, the technician would need to look considerably deeper to notice another OS installed on the system. Most likely, she would see what she expected to and move on.

### Linux with Benefits

Our solution had one drawback: once we set the laptop to boot into Windows automatically, the normal process to boot Linux wouldn't work. That could be annoying once the laptop came back. But our backup Linux install had already solved this problem! We could boot from *that* device, which would load GRUB, which would detect the Mint install on the HDD, which would allow us to boot into that and revert the GRUB configuration.

There were other benefits. Now that I had a disembodied installation with all of my files, I could boot into the SSD using another computer. That way while my laptop was gone I could continue to work and listen to music; it would be almost as if it never left.

### BIOS Fail

In practice, the other machines I had available to me ran either Mac OS X or Windows 8. Unlike my laptop Macs don't run BIOS; they run EFI. Likewise Windows 8 laptops have moved to UEFI. Neither system was eager to let me boot from my SSD. OS X wouldn't even recognize the drive as mountable, and even after disabling Secure Boot the Windows laptop would only give me a cryptic information-less error message when trying to boot.

I could have tried harder to solve this, but given my laptop was only gone a week I didn't find it worth it to do so. When I needed some files I used an EFI-bootable flash drive to boot into Linux on my Mac, copy the files to another partition on the flash drive, and boot back into OSX. It wasn't exactly as convenient as I had envisioned but it worked.

### In Sum

Like all projects of this nature, I think Matt and I spent much more time than we intended and also learned more than we expected. The end result was satisfactory. Right now? I'm typing this on my laptop, listening to Gregorian chant on my sweet headphones through the audio jack.


<sup>1</sup> Pun intended.

