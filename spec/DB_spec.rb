require 'spec_helper'
require 'DB'

describe DB do

  describe '#self.root' do
    # pages = [
    #     {
    #         id: RDF::URI.new("http://id.ukpds.org/page1"),
    #         slug: "",
    #         template: "template1",
    #         path: "/"
    #     },
    #     {
    #         id: RDF::URI.new("http://id.ukpds.org/page2"),
    #         parent: RDF::URI.new("http://id.ukpds.org/page1"),
    #         slug: "a",
    #         template: "template2",
    #         path: "/a"
    #     }
    # ]

    it 'returns the root page - the one whose parent is nil' do
      expect(DB.root).to eq(DB.pages.first)
    end
  end

  describe '#self.find_root_page_by_slug' do
    it 'returns the root page when the slug is ""' do
      expect(DB.find_root_page_by_slug('')).to eq(DB.pages.first)
    end
  end

  describe '#self.find_page_by_slug' do
    it 'returns the root page when the slug is ""' do
      expect(DB.find_root_page_by_slug('')).to eq(DB.pages.first)
    end
  end
end