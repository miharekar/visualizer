module Bsearch
  private

  def closest_bsearch(array, timestamp, key: nil)
    key ||= 0
    index = array.bsearch_index { |x| x[key] >= timestamp } || array.size
    after = array[index]
    before = array[index - 1]
    return before unless after

    (timestamp - before[key]).abs < (timestamp - after[key]).abs ? before : after
  end
end
