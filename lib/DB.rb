class DB
  @@pages = nil

  def self.pages
    page1 = {slug: ''}
    page2 = {slug: 'a', parent: page1}
    page3 = {slug: 'b', parent: page2}
    page4 = {slug: 'c', parent: page2}
    @@pages ||= [page1, page2, page3, page4]

    @@pages
  end

  def self.find_page_by_slug(slug)
    self.pages.select { |page| page[:parent].nil? && page[:slug] == slug }.first
  end

  def self.find_page_by_slug_and_parent(slug, parent)
    self.pages.select { |page| !page[:parent].nil? && page[:slug] == slug && page[:parent][:slug] == parent[:slug] }.first
  end

  def self.generate_path(page)
    path = self.x(page)

    path == '' ? '/' : path
  end

  def self.x(page)
    if page[:parent].nil?
      ''
    else
      self.x(page[:parent]) + '/' + page[:slug]
    end
  end

  def self.root
    self.pages.select do |page|
      page[:parent].nil?
    end.first
  end

  def self.tree(page)
    page[:children] = self.pages.select do |pg|
      pg[:parent] == page
    end

    page[:children].each do |child|
      self.tree child
    end
    page
  end
end