require 'spec_helper'
require 'DB'

describe DB do

  describe '#self.root' do
    it 'returns the root pages - the one whose parent is nil' do
      expect(DB.root).to eq(DB.pages.first)
    end
  end

  describe '#self.find_root_page_by_slug' do
    it 'returns the root pages when the slug is ""' do
      expect(DB.find_root_page_by_slug('')).to eq(DB.pages.first)
    end
  end

  describe '#self.find_page_by_slug_and_parent' do
    it 'returns the third pages when the slug is "a" and the parent is the root' do
      expect(DB.find_page_by_slug_and_parent('a', DB.pages.first)).to eq(DB.pages[2])
    end
  end

  describe '#self.find_parent' do
    it 'returns the root pages when given the id of the root' do
      expect(DB.find_parent(DB.pages.first[:id])).to eq(DB.pages.first)
    end
  end
end