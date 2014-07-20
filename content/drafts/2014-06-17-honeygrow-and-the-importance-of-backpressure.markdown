---
title: Honeygrow and the Importance of Backpressure
date: Tue Jun 17 18:21:22 EDT 2014
subblog: tech
tags: distributed systems
---

### Congratulations, Honeygrow

I'm really glad that a Honeygrow opened this week within walking distance of my office building. There are very few lunch options in the area that are as healthy or delicious. It also seems like a cool, fun place.

I'm going to write about a failure at Honeygrow, but I want to be clear that I don't intend to drag the restaurant down. Instead, I'd like to congratulate them on having the problems that all startups want to be having: growing pains while scaling because they're so darn popular.

So congratulations, Honeygrow, and welcome to Radnor.

### Honeygrow Architecture

An interesting thing about computer science is a lot of it doesn't necessarily have to do with computers. Principles of distributed system design apply to all distributed systems, whether those are software or restaurants.

Honeygrow is a case in point. The restaurant is itself a distributed system. People and food come in, people and food go out, and money is exchanged in the meantime. Here it is in a little more detail:

- Customers enter the restaurant and place their orders at either of two computerized kiosks. They order salad, stir fry, or a couple other things I'll ignore for simplicity's sake.
- Some employees work on filling stir fry orders. The number of stir fries that can be made are limited by the number of woks in operation, maxing out at 3 or 4.
- Some employees work on filling salad orders. Presumably salad production is less constrained since nothing needs to be cooked to order.

There's more to it but that's mostly it. I say the system is distributed because its actions are carried out by multiple specialized actors acting independently. There is no grand maestro getting gt

