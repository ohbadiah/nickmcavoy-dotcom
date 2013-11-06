---
title: Fun with Haskell and Loan Repayment
date: Wed Nov  6 00:23:18 EST 2013
tags: Haskell, personal computing
---

It was time to put Mrs. Parish to the test.

Mrs. Parish was my trigonometry and calculus teacher in 11th and 12th grade. She was a wonderful teacher. That's part of why I remember from her class the claim that:

__"If you make just one extra payment per year on a thirty-year mortgage, you will pay the loan off in only 17 years."__

This promise seemed like a bona-fide secret of life. Save half the time for an incremental increase in effort? Sign me up!

But was it true? I'd meant ever since to go over the math. I turned to my laptop to find out.

<!-- MORE -->

### Forget math

I could have probably solved this problem with math. There are plenty of formulae [readily available](https://en.wikipedia.org/wiki/Mortgage_calculator#Monthly_payment_formula) related to this problem. Plugging those in would be straightforward.

But I wanted to be satisfied I understood what I was doing, if nothing else because otherwise down the line I might not really trust or remember what I found out. And when it comes to understanding, my comparative advantage nowadays is in programming, not in mathematics per se.

I remembered the fundamental law governing continuously-compounding interest:

```
Balance = Principal * e ^ (rate * time)
```

Periodic payments are easy enough to model, too, but an analytic solution for the time when the balance reaches zero did not leap off the page at me.

However, one thing I do know how to do is write a simulation!

### Setting up

The idea is you have a loan with certain principal, annual percentage rate, and suggested monthly payment:

```haskell
data Loan = Loan {
  balance :: Double
, apr     :: Double
, monthly :: Double
} deriving (Show, Eq)

sampleMortgage = Loan 250000 0.05 1342.05
```

Then you want to know, what happens if I make extra payments? Or, since it's probably easier to set up, what happens if I make my monthly payment proportionately larger? Are these approaches interchangeable? We'll call this behavior a RepaymentStrategy:

```haskell
data RepaymentStrategy = Strategy {
  paymentsPerYear   :: Int
, fractionOfMonthly :: Double
} deriving (Show, Eq)
```

I can think of two ways to evaluate the paydown of a loan. The first concern is how long it takes. Maybe you want to get the debt monkey off your back as soon as possible. But it's also possible what you most care about is minimizing the total interest you pay. These two things should go hand in hand, but we'll keep track of them both just to see:

```haskell
data SimProgress = Sim {
  elapsedT      :: Double
, principalPaid :: Double
, interestPaid  :: Double
, totalPayments :: Int
} deriving Eq

type SimResult = Either String SimProgress
```

### Letting the air out

Writing this program helped me develop some intuition for paying down compound interest. As I reasoned I pictured the debt as an inflating balloon.

The debt balloon is always inflating. That's interest. Every now and then you come over and let some air out. That's making a payment.

Leave the balloon alone for long and you will return to find it unmanageably large. That sad reality is particularly true because interest compounds: the air that was just let into the balloon is now letting air into the balloon itself. It's not just that the volume of the balloon (total debt) is increasing; it's that it's increasing at an increasing rate. It's really easy to get into trouble with debt!

So it's best to keep letting the air out. With each trip, you must let out more air than came into the balloon since your last visit, or you'll never get it deflated. If you really want to get ahead, you need to let out a significant amount of air *over and above* the "interest air."

### Writing the sim

In an imperative language, the cycle of payments would be represented by a big `while` loop. Haskell doesn't have those, so we'll have to rely on recursion:

```haskell

paydown :: RepaymentStrategy -> Loan -> SimResult
paydown repaymentStrategy loan = step repaymentStrategy loan initialSimProgress

step :: RepaymentStrategy -> Loan -> SimProgress -> SimResult
step  s@(Strategy perYear fractionOfMonthly) l@(Loan balance apr monthly) sim
  | balance <= 0.01       = Right sim
  | (elapsedT sim) >= 100 = Left "That better not take more than a century to repay."
  | otherwise             = step s (l {balance = balance'}) sim' where
      dt                = 1 / (fromIntegral perYear)
      compoundedBalance = pert l dt
      payment           = monthly * fractionOfMonthly
      balance'          = compoundedBalance - payment
```

Our top-level function `paydown` winds up its recursive child `step` and sets it running. `step` first checks to see whether the loan it has been handed has already been paid off; if so the recursion can stop and a successful result can be returned. Then, it sees if it's taking more than a century to pay down the loan; if so there is probably something wrong and we will just exit the sim with an error message.

Barring those scenarios, we will let the balloon inflate for another payment period and then let some air out. The inflation (compounding) is defined by the "pert" formula listed above.<sup>1</sup>  Our only inherent limitation should be the imperfections of floating point arithmetic, which I do not think will hurt us much.

Other than that, we figure out how much our payment is and we take it off the top. Phewww

### Results

Was Mrs. Parish right? We turn to `ghci`, first with a sanity check:

```
*Sim> sampleMortgage
Loan {balance = 250000.0, apr = 5.0e-2, monthly = 1342.05}

*Sim> paydown defaultRepaymentStrategy sampleMortgage
Right The loan will be paid down in 30 years, 1 months.
The composition of the payoff was  51.602483068740824 % principal, and 48.39751693125917 % interest.
```

Yeah, yeah, our `Show` instance is beat. So what. More importantly, you might wonder if we have an off-by-one error: this is supposed to be a 30-year mortgage, not a 361-monther. But there are enough subtle differences between our sim and reality, for instance rounding to the cent, that I'm not going to worry about the small discrepancy.

Okay, Mrs. Parish, now *I* am handing *you* a moment of truth:

```
*Sim> paydown defaultRepaymentStrategy {paymentsPerYear = 13} sampleMortgage
Right The loan will be paid down in 25 years, 4 months.
The composition of the payoff was  56.62623594541301 % principal, and 43.373764054586985 % interest.
```

Lies! I was promised 17 years, not 25! Or so I remember; I could be wrong. In any case, our 25 extra payments over 25 years saved us 45 payments in the long run! The interest proportion of our payment went down 5%! Considering that adding a twelfth to our payments is unlikely to make a significant difference to our budget, this move easily seems worth making.

What happens if we are even more aggressive in our extra payments?

```
*Sim> paydown defaultRepaymentStrategy {fractionOfMonthly = 13/12} sampleMortgage
Right The loan will be paid down in 25 years, 4 months.
The composition of the payoff was  56.63780738517451 % principal, and 43.362192614825496 % interest.

*Sim> paydown defaultRepaymentStrategy {fractionOfMonthly = 5/4} sampleMortgage
Right The loan will be paid down in 19 years, 6 months.
The composition of the payoff was  63.841323906512834 % principal, and 36.15867609348716 % interest.

*Sim> paydown defaultRepaymentStrategy {fractionOfMonthly = 6/4} sampleMortgage
Right The loan will be paid down in 14 years, 8 months.
The composition of the payoff was  70.89140748962909 % principal, and 29.10859251037091 % interest.

*Sim> paydown defaultRepaymentStrategy {fractionOfMonthly = 7/4} sampleMortgage
Right The loan will be paid down in 11 years, 10 months.
The composition of the payoff was  75.61532395309146 % principal, and 24.38467604690854 % interest.

*Sim> paydown defaultRepaymentStrategy {fractionOfMonthly = 8/4} sampleMortgage
Right The loan will be paid down in 9 years, 11 months.
The composition of the payoff was  78.94371001656597 % principal, and 21.056289983434027 % interest.

*Sim> paydown defaultRepaymentStrategy {fractionOfMonthly = 3} sampleMortgage
Right The loan will be paid down in 6 years, 1 months.
The composition of the payoff was  86.39320510227122 % principal, and 13.606794897728777 % interest.

*Sim> paydown defaultRepaymentStrategy {fractionOfMonthly = 4} sampleMortgage
Right The loan will be paid down in 4 years, 4 months.
The composition of the payoff was  89.76061139861294 % principal, and 10.23938860138706 % interest.

*Sim> paydown defaultRepaymentStrategy {fractionOfMonthly = 5} sampleMortgage
Right The loan will be paid down in 3 years, 5 months.
The composition of the payoff was  91.89421558703962 % principal, and 8.105784412960372 % interest.
```

### Conclusion

First, we see the rough equivalence of making more payments and making bigger payments. More payments are a little better because air is let out more frequently, preventing new air from bringing in newer air, but it doesn't make much difference here.

Second, we see that incremental increases in the payment make a huge difference! Increasing payments by a fourth cuts repayment time by a third, and doubling it does so by more than two thirds.

Third, we see our increases bring us diminishing benefit. Paying an extra 50% has a far greater impact than going from 2x to 3x our payment.

Based on these data, we begin to see the grounds for a more optimum loan-repayment strategy. In general, we *will* want to pay slightly more than the suggested payment on a loan, both in order to finish it faster and to pay less interest. However, we probably do not need to go overboard in doing so; more extreme increases won't decrease repayment time or interest burden very much.

Thanks, Mrs. Parish!

### Source

You can find the source for these calculations [here](https://github.com/ohbadiah/loan-repayment).

<BR />

###### <sup>1</sup> One nice thing about this formula is it is exact. Unlike the case of, say, a simulation of a projectile, the size of our time slice is not a limiting factor. Our simulation can visit the balloon only at payment time without loss of accuracy.
