class Sender < ActiveRecord::Base
  has_many :steps, dependent: :destroy
  validates_presence_of :facebook_id, :navigation_status
  validates_uniqueness_of :facebook_id

  def self.recreate(facebook_id)
    sender = Sender.find_by_facebook_id facebook_id
    sender.destroy if sender

    sender = Sender.new
    sender.facebook_id = facebook_id
    sender.navigation_status = 0
    sender.steps = Array.new
    sender.save if sender.valid?
    sender
  end

end
