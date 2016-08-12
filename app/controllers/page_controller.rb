require 'DB'

class PageController < ApplicationController
  def show
    page = DB.find_page params[:path]
  end
end
