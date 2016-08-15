require 'DB'

class SitemapController < ApplicationController
  def show
    pages = DB.pages

    sitemap_builder = Nokogiri::XML::Builder.new do |xml|
      xml.urlset(xmlns: 'http://www.sitemaps.org/schemas/sitemap/0.9') {
        pages.each do |page|
          xml.url {
            xml.loc request.base_url + page[:path]
            xml.changefreq 'always'
            xml.priority 0.5
          }
        end
      }
    end

    render xml: sitemap_builder
  end
end
