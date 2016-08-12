class DB
  @@pages = nil

  def self.pages
    page1 = {:slug => "a"}
    page2 = {:slug => "b", :parent => page1}
    @@pages ||= [page1, page2]

    @@pages
  end

  def self.find_page(path)
    self.pages.select { |page| page[:slug] == path }.first
  end
end