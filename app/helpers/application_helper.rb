module ApplicationHelper
  def title(page_title)  
    content_for(:title) { page_title }  
  end
  def fancybox(enabled)
    content_for(:fancybox) { enabled }
  end
end
