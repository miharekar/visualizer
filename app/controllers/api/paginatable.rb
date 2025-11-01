module Api
  module Paginatable
    def paginate(relation, with_counts: true)
      page = [params[:page].to_i, 1].max
      limit = params[:items].presence.to_i
      limit = 10 if limit.zero?
      limit = [limit, 100].min

      if with_counts
        count = relation.count(:all)
        pages = (count.to_f / limit).ceil
        page = pages if page > pages && pages > 0
      end

      offset = (page - 1) * limit
      records = relation.offset(offset).limit(limit)

      [records, {count:, page:, limit:, pages:}]
    end
  end
end
