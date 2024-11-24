class CustomAudit < Audited::Audit
  before_create :set_stripe_event_id

  private

  def set_stripe_event_id
    self.stripe_event_id = Audited.store[:stripe_event_id]
  end
end