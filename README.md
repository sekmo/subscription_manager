# Subscription Manager

## Description

Write a simple rails application that receives and processes events from Stripe.

### Acceptance criteria

- creating a subscription on stripe.com (via subscription UI) creates a simple subscription record in your database
- the initial state of the subscription record should be "unpaid"
- paying the first invoice of the subscription changes the state of your local subscription record from "unpaid" to "paid"
- canceling a subscription changes the state of your subscription record to “canceled”
- only subscriptions in the state “paid” can be canceled

## Assumptions and considerations

Regarding the scope of this application, the assumption is that the primary purpose of the system is to identify when a customer should have access to our services based on their subscription status in Stripe. Other than the customer stripe id and subscription stripe id, we might need to store additional customer data like name and email so we are able to reference these fields in other parts of our system.
We might also want to store extra information like the stripe events id for auditing purposes in case of bugs or security problems.

When implementing an integration with an external API, there are several considerations to take into account. In this case, we know the following:

- Stripe does not guarantee the order of webhook event delivery, so we need to handle out-of-order messages. Additionally, events may arrive with a delay.
- Stripe guarantees at-least-one delivery, meaning that we may receive duplicated events, so we need to handle them accordingly.

## Implementation

This is a Rails application in API-only mode, with postgresql as a database, sidekiq for background jobs and redis as a in-memory store. Only some middleware related to sessions was added in order to use the sidekiq web admin.

The task specifies that only paid subscriptions can be canceled. We rely on the aasm gem to enforce these kind of rules through a state machine. If our system encounters invalid transition exceptions, the errors are logged, and additionally we can track them with services like Rollbar/Sentry.

We use the Audited gem to track the status changes of the Subscription model, and log the stripe event id. Even that this feature may impact the db performance, I believe it is beneficial since this data might be useful in case of debugging and/or security breaches we might need to investigate.

The application implements background jobs to process the events asynchronously, allowing us to respond quickly to the stripe events. The jobs are idempotent and resilient to out-of-order events, since stripe does not guarantee events order, and we may also receive duplicated events.

Concurrency has also been considered in the implementation. I took into account that `create_or_find_by` is not 100% race-condition free, but that might only happen in the rare case when we try the insert, fail on a uniqueness constraint violation, then in the meanwhile another concurrent request deletes the row, we run the select and no row is found. The assumption is that our application doesn't need to delete rows when stripe can send us events related to these specific records. In that specific case we can implement a rescue-retry or also implement a soft-deletion mechanism to mark the model as deleted.

In the stripe webhook settings, we can also configure which events we want to receive. This prevents stripe from bombarding us with unnecessary events that we don't need to handle, reducing noise and optimizing performance.

Regarding security, the endpoint is protected by verifying the stripe signature, using the Stripe library.
Additionally, we can whitelist the Stripe IP addresses in our network components to provide an extra layer of security.


### Subscription status update details

Per the initial design, our application handles 3 kind of events: subscription created, Invoice paid, subscription canceled. This means that, with the default stripe settings, our local subscription remains in the paid state even that the customer doesn't pay the invoices for the next subscription cycles.

Depending on our needs, in the Stripe billing configuration we can set the option to cancel a subscription once a customer invoice is past due 30/60/90 days.

By doing so Stripe will send us the `customer.subscription.deleted` event when an invoice is past due, and that will be reflected in our system by setting the subscription status to "canceled". However, we need to consider that when a subscription is canceled, and our customer wants renew our service, we will need to create a new subscription, because in Stripe "canceled" is a final state for a subscription, and we can no longer update the subscription or its metadata.

An improvement might be to adjust the Stripe Billing settings so that subscriptions are marked as "past due" instead of being canceled. This would allow us to handle subscription status update in our system so that we can update our subscription status back to "unpaid" instead. Then, when the customer explicitly cancels the subscription, we can reflect the status change to our system.


## How to run this application

This is a Ruby on Rails application in API-only mode, using PostgreSQL as database.
Is using Rails 7.2.1 and Ruby 3.3.6, and has been dockerized with a modified version of [this repo](https://github.com/nickjj/docker-rails-example) as starting point. Please run the following commands in order to start the application:

#### Copy the example .env file:

```sh
cp .env.example .env
```

#### Setup the stripe listener

```sh
stripe listen --forward-to localhost:8000/api/v1/stripe_events
```
In this way we will know the webhook signing secret that we can set below.


#### Add your Stripe keys to the .env file:
Add your Stripe API key and your Stripe webhook signing secret

```sh
export STRIPE_API_KEY="sk_test_....."
export STRIPE_WEBHOOK_SECRET="whsec_e0eb42....."
```

#### Build everything and start the app:

```sh
docker compose up --build
```

The application is running at `localhost:8000`.
PostgreSQL is exposed on the port `5499`, with user `subscription_manager`, password `password`.
Sidekiq admin is available at `http://localhost:8000/sidekiq`

#### Create and migrate the database:

```sh
./run rails db:prepare
```

#### Receive real stripe events

Now that our stripe listener is forwarding events to our endpoint, we can receive and process stripe events using the stripe dashboard or using the stripe CLI.
Creating customers is easier being done on the stripe dashboard, because to enable sending payment details on the CLI, even in test mode, we need to contact the support.

Some CLI command examples:

```sh
# get products
stripe products list

# get prices
stripe prices list --product prod_RF5bHsE8eohoFm

# create subscription with send invoice as collection method
stripe subscriptions create --collection-method send_invoice --days-until-due 30 --customer cus_RHfnYDKffI7ob7 -d 'items[0][price]=price_1QMbQaKvFeX4s4udng70Kivu'
# then we can simulate an invoice becoming past due using the stripe test clocks running a simulation on the stripe dashboard.

# create and pay subscription
stripe subscriptions create --customer cus_RHfnYDKffI7ob7 -d 'items[0][price]=price_1QMbQaKvFeX4s4udng70Kivu'

# list subscriptions for a customer
stripe subscriptions list --customer cus_RHfnYDKffI7ob7 | jq '.data[].id'

# get invoices
stripe invoices list --customer cus_RHfnYDKffI7ob7  | jq '.data[].id'
stripe invoices list --subscription=sub_1QOl7KKvFeX4s4ud0YUd1VJd | jq '.data[].id'

# pay invoice
stripe invoices pay in_1QNhRMKvFeX4s4udb6730SJ0

# cancel subscription
stripe subscriptions cancel -c sub_1QNhbEKvFeX4s4uddWS7HPcI

# resend an event
stripe events resend evt_1QNhdbKvFeX4s4ud7NQzx1GT
```

#### How to run the tests
The test suite includes unit tests and integration tests with fixture examples taken from real events.

```sh
./run test
```