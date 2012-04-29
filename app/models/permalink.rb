class Permalink < ActiveRecord::Base
  acts_as_tree
  belongs_to :linkable, :polymorphic => true
  
  validates :link, {
              :uniqueness => { :case_sensitive => false },
              :presence => true,
              :length => { :in => 1..40 },
              :format => { :with => /^[a-zA-Z0-9_\-]+$/ }
            }
  
  validates :linkable, {
              :presence => true
            }
            
  validate :link_cannot_be_a_recognized_route
  validate :link_cannot_be_reserved
  
  private

  def link_cannot_be_a_recognized_route
    result = Rails.application.routes.recognize_path("/#{link}")
    unless result[:controller] == 'permalinks' && result[:permalink] == link
      errors.add(:link, "is reserved")
    end
  end
  
  def link_cannot_be_reserved
    if ['coke','mgm','sony','paramount','mobile','pepsi','warner','warnerbros','target'].include?(link.downcase)
      errors.add(:link, "is reserved")
    end
  end
end
