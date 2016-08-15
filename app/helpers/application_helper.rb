require 'DB'

module ApplicationHelper
  def navigation_menu
    render partial: 'shared/navigation_menu', locals: {node: DB.root}
  end

  def breadcrumbs path
    pages = DB.find_ancestry_by_path path

    render partial: 'shared/breadcrumbs', locals: {pages: pages}
  end

  def breadcrumbs_json_ld path
    breadcrumbs = {
        '@context': 'http://schema.org',
        '@type': 'BreadcrumbList',
        itemListElement: DB.find_ancestry_by_path(path).map.with_index do |page, index|
          {
              '@type': 'ListItem',
              position: index + 1,
              item: {
                  '@id': request.base_url + page[:path],
                  'name': page[:slug] == '' ? 'home' : page[:slug],
                  'image': ''
              }
          }
        end
    }

    content_tag(:script, breadcrumbs.to_json.html_safe, type: 'application/ld+json')
  end
end