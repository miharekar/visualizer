module Bsearch
  private

  def closest_bsearch(array, timestamp, key: nil)
    index = array.bsearch_index { |x| (key ? x[key] : x[0]) >= timestamp } || array.size
    [array[index], array[index - 1]].compact.min_by { |x| (timestamp - (key ? x[key] : x[0])).abs }
  end
end
