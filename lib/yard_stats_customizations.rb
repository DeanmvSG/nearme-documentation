class YARD::CLI::Stats

  METHODS_SKIP_FOR_PATHS = [
                             /^ActionTypeDrop/,
                             /LocationDrop#model_name/,
                             /^LiquidFilters#get_lowest_price_with_options/,
                             /^ReservationRequestDrop/
                           ]

  CLASSES_SKIP_FOR_PATHS = [
                             /^RenderFeaturedItemsTag/
                           ]

  def should_skip_for_path(type, object)
    result = false
    "YARD::CLI::Stats::#{type.to_s.pluralize.upcase}_SKIP_FOR_PATHS".constantize.each do |skip_expr|
      if skip_expr.match(object.path)
        result = true
        break
      end
    end
    result
  end

  def has_return_tag?(object)
    has_docstring = object.docstring.to_s != ''
    object.tags.each do |tag|
      if tag.tag_name == 'return' && (tag.text != '' || object.attr_info || has_docstring)
        return true
      end
    end

    false
  end

  def print_statistics
  end

  def print_undocumented_objects
    # Reject for not used paths
    objects = all_objects.select do |object|
      if object.is_a?(YARD::CodeObjects::ClassObject)
        if object.file.match(/app\/liquid_tags\/.+?\.rb/) && !object.path.match(/::/) && !should_skip_for_path(:class, object)
          true
        else
          false
        end
      elsif object.is_a?(YARD::CodeObjects::MethodObject)
        if (object.file.match(/app\/drops\/.+?\.rb/) || object.file.match(/lib\/liquid_filters\.rb/)) && !object.path.match(/BaseDrop/) && !should_skip_for_path(:method, object)
          true
        else
          false
        end
      else
        false
      end
    end

    # Reject those with documentation
    objects = objects.select do |object|
      if object.is_a?(YARD::CodeObjects::ClassObject)
        if object.docstring.to_s.blank?
          true
        else
          false
        end
      elsif !has_return_tag?(object) || object.docstring.to_s.match(/^Alias for/)
        true
      else
        false
      end
    end

    # Now we add back to objects those delegates which have been removed but whose comments still linger
    method_objects = all_objects.select { |o| o.is_a?(YARD::CodeObjects::MethodObject) }
    method_objects.each do |object|
      if !object.is_explicit? && object.group != "Delegated Instance Attributes" && !object.attr_info && !object.is_alias?
        objects << object
      end
    end

    objects.uniq!

    objects = objects.sort_by {|o| o.file.to_s }

    last_file = nil
    objects.each do |object|
      if object.file != last_file
        puts
        puts "(in file: #{object.file || "-unknown-"})"
      end
      puts object.path
      last_file = object.file
    end

    if Dir.exists?('.yardoc')
      FileUtils.remove_dir('.yardoc', true)
    end

    if objects.count == 0
      exit(0)
    else
      exit(1)
    end
  end

end
