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
    @templates = DB.find_templates
    @parents = DB.potential_parents
    @parents_dropdown_data = @parents.map { |parent| [ parent[:title], parent[:uri] ] }.to_h
  end

  def create
    subject = RDF::URI.new("http://id.ukpds.org/#{params[:new_slug]}")
    statemtents_to_add = [
        create_statement(subject, "http://www.w3.org/1999/02/22-rdf-syntax-ns#type", RDF::URI.new("http://data.parliament.uk/schema/parl#Page")),
        create_statement(subject, "http://data.parliament.uk/schema/parl#slug", params[:new_slug]),
        create_statement(subject, "http://data.parliament.uk/schema/parl#title", params[:new_title]),
        create_statement(subject, "http://data.parliament.uk/schema/parl#parent", RDF::URI.new(params[:parent])),
        create_statement(subject, "http://data.parliament.uk/schema/parl#template", params[:template]),
        create_statement(subject, "http://data.parliament.uk/schema/parl#text", params[:new_text])
    ]
    update_graph(statemtents_to_add, true)
    DB.reload
    redirect_to root_path
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
