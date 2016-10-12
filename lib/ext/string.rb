class String
  def intersection(other)
    str = dup
    other.chars.inject(0) do |sum, char|
      sum += 1 if str.sub!(char, '')
      sum
    end
  end

  def to_yml_key
    gsub(/[\-|\/|\.]/, '_').downcase
  end
end
