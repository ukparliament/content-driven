require 'DB'

class PageBase
  def initialize(page, controller)
    @page = page
    @controller = controller
  end

  def render
    @controller.render 'templates/' + @page[:template], locals: {current_page: @page}
  end
end

module A
  class Reload < PageBase
    def initialize(page, controller)
      super(page, controller)

      DB.reload
    end
  end
end

class PageController < ApplicationController
  def show
    path = normalize_path

    begin
      db_page = DB.find_page_by_path(path)

      app_page = get_page(db_page)

      app_page.render

    rescue ActionController::RoutingError
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  private

  def normalize_path
    # TODO: remove slug altogether for root page


    #empty string needed for the root path
    params[:path] || ''
  end

  def get_page(page)
    page_type = page[:type]

    page_class = page_type == '' ? PageBase : Object::const_get(page_type)

    page_class.new(page, self)
  end
end
