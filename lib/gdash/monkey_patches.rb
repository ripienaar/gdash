class Array
  def in_groups_of(chunk_size, padded_with=nil)
    if chunk_size <= 1
      if block_given?
        self.each{|a| yield([a])}
      else
        self.collect{|a| [a]}
      end
    else
      arr = self.clone

      # how many to add
      padding = chunk_size - (arr.size % chunk_size)
      padding = 0 if padding == chunk_size

      # pad at the end
      arr.concat([padded_with] * padding)

      # how many chunks we'll make
      count = arr.size / chunk_size

      # make that many arrays
      result = []
      count.times {|s| result <<  arr[s * chunk_size, chunk_size]}

      if block_given?
        result.each{|a| yield(a)}
      else
        result
      end
    end
  end
end

class GraphiteGraph
  attr_accessor :properties, :file
end

class Hash
  def rmerge!(other_hash)
    merge!(other_hash) do |key, oldval, newval|
      oldval.class == self.class ? oldval.rmerge!(newval) : newval
    end
  end
end
