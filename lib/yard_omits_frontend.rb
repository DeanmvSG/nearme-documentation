class CustomVerifier < YARD::Verifier
  def run(obj_list)
    obj_list.reject do |obj|
      # Allowed parent objects
      if obj.is_a?(YARD::CodeObjects::ClassObject) && obj.path.match(/^Transactable$/) ||
        obj.is_a?(YARD::CodeObjects::ModuleObject) && obj.path.match(/^Support$/)
        false
      else
        # All other objects
        if (obj.is_a?(YARD::CodeObjects::ClassObject) && !obj.path.match(/Drop$/)) || 
          (obj.is_a?(YARD::CodeObjects::ModuleObject) && !obj.path.match(/LiquidFilters/))
          true
        else
          false
        end
      end
    end
  end
end

class YARD::CLI::YardocOptions

  def verifier
    CustomVerifier.new
  end

end
