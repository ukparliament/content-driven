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

  class NotFound < PageBase
    def render
      @controller.render 'templates/' + @page[:template], locals: {current_page: @page}, status: 404
    end
  end
end

class PagesController < ApplicationController
  def new
    @page = { }
    @templates = ["template1", "template2"]
    @parents = [{title: 'a', uri: 'http://test.com/1'}, {title: 'b', uri: 'http://test/com/2'}]
    @parents_dropdown_data = @parents.map { |parent| [ parent[:title], parent[:uri] ] }.to_h
  end

  def create
    raise params
  end

  def show
    path = normalize_path
    begin
      find_and_render(path)

    rescue ActionController::RoutingError
      find_and_render('404')
      # raise ActionController::RoutingError.new('Not Found')
    end
  end

  def find_and_render(path)
    db_page = DB.find_page_by_path(path)

    app_page = get_page(db_page)

    app_page.render
  end

  private

  def normalize_path
    #empty string needed for the root path
    params[:path] || ''
  end

  def get_page(page)
    page_type = page[:type]

    page_class = page_type == '' ? PageBase : Object::const_get(page_type)

    page_class.new(page, self)
  end
end
