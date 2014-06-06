---
title: Pallet for Automation and Profit
date: Tue May 27 09:43:32 EDT 2014
subblog: tech
tags: devops, Clojure
---

There are a million little projects I would like to build in my spare time and have sitting out there on the Internet. It's tempting to get hacking on them as soon as I think of them, but that ignores an entire world of things that need to happen between committing the code and having it running on the Web.

Before software can be run, it needs to be deployed. Before it can be deployed, a server needs to be provisioned and waiting for it. Of course all of this can be done manually, but that only makes sense when n=1, i.e. never. So we'll automate that, and while we're at it we might as well try and mix in some of our favorite principles from software engineering proper, such as repeatability (idempotence?) and even immutability.

Chef and Puppet are the most popular tools for this kind of automation. At Relay we use Chef. I did not want to use either because I'm difficult like that; I'm not going to spend my free time writing Ruby or python if there is a good alternative. So I turned to Pallet.

<!-- MORE -->

### About Pallet

Pallet is a Clojure project, so you could almost say it had me at `(println "Hello")`. I'm not any kind of an expert in Chef and I've never touched Puppet, so I don't have a great idea of what each system's distinctives are. But as far as I can tell here are some of Pallet's emphases:

- Pallet's work does not start with a running virtual private server. Pallet uses JClouds to talk to cloud providers directly in doing things like spinning up server instances.

- Nor does Pallet's work finish when the server is provisioned. It can apparently be used to deploy your software, to start and stop services, and even to run administrative tasks. "To be honest," the documentation admits, "this wasn't an initial design goal, but has come out of the wash that way."

- Pallet doesn't require any software to be installed on your destination servers. It just executes all of its commands over ssh from whatever JVM you run it on. This seems simpler than Chef to me.

### Using Pallet

I created a Pallet template using Clojure's build tool, Leiningen. It being a Clojure project, I loaded it into a new `lein repl` and was thus able to develop and execute right from my connected Emacs buffer.

For all of my projects I envision the same basic setup. Just like at Relay, I'll put nginx in front of ports 80 and 443 and use it to serve up static assets and reverse proxy through to other webservers running for specific projects. Most of my projects will probably run on the JVM, so I'll need to install java. And git will probably be necessary.  So, for my first milestone I thought I would get a vps running with nginx, java, and git. 

As for a target first project, this blog used to run embedded in a Play! framework app on Heroku, but I wanted to start hosting it in a vps. So I thought I'd start with the words you're reading. Simple.

Here's what I ended up with:

```clojure
(ns nmdc.groups.nmdc
  "Node defintions for nmdc"
  (:require
   [pallet.api :refer [group-spec server-spec node-spec plan-fn]]
   [pallet.compute :as compute]
   [pallet.crate.automated-admin-user :refer [automated-admin-user]]
   [pallet.crate.git :as git-crate]
   [pallet.crate.java :as java-crate]
   [pallet.crate.nginx :as nginx-crate]))

(def nginx-config
;; .....
)

(def
 ^{:doc "Define a server spec for nmdc"}
 nmdc-server
 (server-spec
  :extends [(git-crate/git {})
            (java-crate/server-spec {:vendor :openjdk
                                     :components #{:jdk :jre}
                                     })
            (nginx-crate/nginx nginx-config)]))

(def nmdc-nodes
     (pallet.compute/instantiate-provider
      "node-list"
      :node-list [["prod" "nmdc" "107.170.182.57" :ubuntu]]))

(defn provision-nmdc []
  (pallet.api/lift
  (group-spec
    "nmdc"
    :extends [nmdc-server]
    :node-spec (node-spec
      :image {:os-family :ubuntu}
      :hardware {:min-cores 1}))
   nmdc-group
   :compute nmdc-nodes
   :phase [:install :settings :configure :reload]))

(comment

  (def next-run (provision-nmdc))
  (-> next-run :results first :result)
)

```

If you can scrutinize the syntax a little bit, you'll see the above code is about as simple as you could want for the task I described. A `server-spec` declares that I want to install git, java, and nginx. Then in a `node-list` I say my server is at a certain IP address running ubuntu. Then in my `provision` function I apply that spec to that server, executing phases for installing and configuring the software and reloading the nginx configuration.

I didn't bother hooking Pallet up to my cloud provider digitalocean's api directly because for the foreseeable future my projects will be able to run on single instances and there's no reason to use a shotgun to kill an ant.

The only weird thing about this process for me was specifying the nginx configuration. Instead of giving the crate some relative path to the config files I want installed, it has me pass in the configuration in the form of a Clojure map. I thought that was weird. Maybe there's a way to specify config files without cloning and modifying the crate itself; I'll have to see.

### In sum

I don't know if Pallet will ultimately prove a better choice than Chef or not. I was definitely able to get up and running with it faster than I could with Chef, but since the user base is smaller by at least an order of magnitude I may have to roll my own crates more often than I might with Chef. I'm also not sure how much Pallet actually takes functional principles to heart and how much it's just a slightly more appealing wrapper for bash.

At any rate, I plan to keep using it and I'm happy with what I've done so far.
