module Enumerable
  def group_by
    inject({}) do |grouped, element|
      (grouped[yield(element)] ||= []) << element
      grouped
    end
  end
end
