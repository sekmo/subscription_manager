# Subscription Manager

**Task**
Write a simple rails application that receives and processes events from Stripe.

**Acceptance criteria**

- creating a subscription on stripe.com (via subscription UI) **creates a simple subscription record in your database**

- the **initial state** of the subscription record should be **'unpaid'**

- **paying the first invoice** of the subscription changes the state of your local subscription record **from 'unpaid' to 'paid'**

- canceling a subscription changes the state of your subscription record to “canceled”

- **only subscriptions in the state “paid” can be canceled**

**Assumptions**

Regarding the purpose of this application, the assumption is that we are implementing this system to mainly tell when a customer should have access to our service depending on the subscription status in Stripe. We might want to store customer data like name and email so we are able to reference these fields in other parts of our system.

**Implementation**

The application is a Rails api-only mode. Only some middleware related to sessions were added to use the sidekiq web admin.

The task says "Only paid subscriptions can be canceled": we rely on the aasm gem to enforce these kind of rules through a state machine. If our system encounters aasm exceptions we we log the error with services like Rollbar. If the cause is that the message was out of order, it's no problem since we have sidekiq retries.

We use the Audited gem to track the status changes of the Subscription model, and log down the stripe event id. Even that the database in this case gets a performance hit, I think that this is beneficial since this data might be useful in case of debugging and/or security breaches we might need to investigate. 


**Considerations**

There are some considerations that we have to take into account when implementing an integration with en external API, and in this case we know the following:

- Stripe doesn't guarantee for the order in which webhooks events are delivered, we need to handle out-of-order messages

- Stripe guarantees at-least-one delivery, meaning that we can receive duplicated events, so we need to handle that as well

**Invoicing**

Per the initial design, our application handles 3 kind of events: subscription created, Invoice paid, subscription canceled.

When a new subscription created event is received, we create a new Subscription record with an initial "unpaid" status. 

Depending on our needs, in the Stripe billing configuration we can set the option to **cancel a subscription** once a customer invoice is past due 30/60/90 days.

By doing so Stripe will send us the `customer.subscription.deleted` event when that happens, and that will be reflected in our system by setting the subscription to "canceled". But we need to consider that when a subscription is canceled, and our customer wants renew our service, we will need to create a new subscription, since in Stripe when a subscription is canceled, we can no longer update the subscription or its metadata.

I thought that a better solution might be to set the Stripe Billing settings so that it marks the Subscription as "past due" instead of canceling it, and handle in our system the subscription status update so that we can set our subscription as "unpaid".



**Security and performance**

- We respond quickly and use background jobs to process the events

- We should check the webhook signing secret

- We should check idempotency key

- We should set **which subset of events** we want to receive on our webhook to avoid Stripe bombarding us with events we're not interested to


**Action plan**

- **Create subscription model to persist stripe subscription data**

- **Implement subscription enum for unpaid, paid, canceled**

- **Create new endpoint for receiving stripe events**

- **Implement unpaid subscription creation when receiving stripe event**

- **Add background job for processing the event instead of creating the subscription directly in the controller**

- **Implement customer create when receiving stripe events (stripe cus id and email)**

- **Implement subscription state change to paid**

- **Implement subscription state change to canceled**

- **Implement state machine to enforce subs state changes rules**

- **Handle receiving duplicated subscription creation**

- **Handle receiving duplicated invoice paid event**

- **Handle receiving duplicated subscription canceled event**

- **Handle receiving invoice.paid before subscription creation**

- **Implement subscription unpaid status update**

- Add subscription cycle/end?

- **Store subscription state changes**

- **Log stripe event ids**

- **Implement retries in case of out-of-order requests**

- High priority queue for subscription creation?

- **Handle duplicated requests**

- Add webhook signing secret check (sent by the stripe listen automatically)

- Handle security - idempotency key?


## How to run this application

This is a Ruby on Rails application in api-only mode, using PostgreSQL as database.
Is using Rails 7.2.1 and Ruby 3.3.6, and has been dockerized with a modified version of [this repo](https://github.com/nickjj/docker-rails-example) as starting point. Please run the following commands in order to start the application:

#### Copy the example .env file:

```sh
cp .env.example .env
```

#### Add your Stripe keys to the .env file:

```sh
export STRIPE_API_KEY="sk_test_....."
```

#### Build everything and start the app:

```sh
docker compose up --build
```

The application is running at `localhost:8000`.\
PostgreSQL is exposed on the port `5499`, with user `reedsystore`, password `password`.

#### Create, migrate, and seed the database:

```sh
./run rails db:prepare
```

#### Run the tests:

```sh
./run test
```