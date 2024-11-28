module Api
  module Paginatable
    def paginate(relation)
      limit = params[:items].presence.to_i
      limit = 10 if limit.zero?
      limit = [limit, 100].min
      count = relation.count(:all)
      pages = (count.to_f / limit).ceil
      page = [params[:page].to_i, 1].max
      page = pages if page > pages && pages.positive?

      offset = (page - 1) * limit
      records = relation.offset(offset).limit(limit)

      [records, {count:, page:, limit:, pages:}]
    end
  end
end
