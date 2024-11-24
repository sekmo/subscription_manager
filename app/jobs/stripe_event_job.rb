class StripeEventJob < ActiveJob::Base
  around_perform do |job, block|
    Audited.store[:stripe_event_id] = job.arguments.first[:id]
    block.call
  end
end
