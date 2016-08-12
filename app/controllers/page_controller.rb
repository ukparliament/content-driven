require 'DB'

class PageController < ApplicationController
  def show
    path = params[:path] || ''
    #empty string needed for the root path
    path_components = [''] + path.split('/') #refactor
    page = nil

    pages = path_components.map.with_index do |component, index|
      if index == 0
        page = DB.find_page_by_slug component
      else
        page = DB.find_page_by_slug_and_parent component, page
      end
    end

    if pages.any? { |page| page.nil? }
      raise ActionController::RoutingError.new('Not Found')
    end

    pages.each do |page|
      page[:path] = DB.generate_path page
    end

    DB.tree DB.root

    @data = { current_page: pages.last, pages: pages, db: DB }
  end
end
