class Image < ActiveRecord::Base
  validates_presence_of :step_id, :uri, :width, :height
  belongs_to :step
  mount_uploader :uri, ImageUploader
end
