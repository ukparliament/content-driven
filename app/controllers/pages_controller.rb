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

  class AddPage < PageBase
    def initialize(page, controller)
      super(page, controller)
      @new_page = { }
      @templates = DB.find_templates
      parents = DB.potential_parents
      @parents_dropdown_data = parents.map { |parent| [ parent[:title], parent[:uri] ] }.to_h
      if @controller.request.post?
        page = @controller.generate_new_page(@controller.params)
        statements_to_add = @controller.generate_statements(page)
        @controller.update_graph(statements_to_add, true)
        DB.reload
      end
    end

    def render
      @controller.render 'templates/' + @page[:template], locals: { page: @new_page, templates: @templates, parents_dropdown_data: @parents_dropdown_data }
    end
  end

  class EditPage < PageBase
    def initialize(page, controller)
      super(page, controller)
      if @controller.request.get?
        current_path = @controller.params[:current_path]
        @current_page = DB.find_page_from_database("http://id.ukpds.org/#{current_path}")
        @templates = DB.find_templates
        parents = DB.potential_parents
        @parents_dropdown_data = parents.map { |parent| [ parent[:title], parent[:uri] ] }.to_h
      end

      if @controller.request.post?
        @current_page = DB.find_page_from_database(@controller.params[:uri])
        statements_to_delete = @controller.generate_statements(@current_page)
        @controller.update_graph(statements_to_delete, false)

        new_page = @controller.generate_new_page(@controller.params)
        statements_to_add = @controller.generate_statements(new_page)
        @controller.update_graph(statements_to_add, true)

        DB.reload
      end
    end

    def render
      if @controller.request.post?
        @controller.redirect_to @controller.root_path
      else
        @controller.render 'templates/' + @page[:template], locals: { page: @current_page, templates: @templates, parents_dropdown_data: @parents_dropdown_data }
      end
    end
  end
end

class PagesController < ApplicationController

  def show
    path = normalize_path
    begin
      find_and_render(path)

    rescue ActionController::RoutingError
      find_and_render('404')
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
