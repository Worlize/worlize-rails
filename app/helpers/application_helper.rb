module ApplicationHelper
  def title(page_title)  
    content_for(:title) { page_title }  
  end
  def fancybox(enabled)
    content_for(:fancybox) { enabled }
  end
  def page_id(id)
    content_for(:page_id) { id }
  end
end
