module Trusty
  module Utilities
    module Yaml
      module ClassMethods
        def load_file(filename, paths = [], &block)
          # allow multiple filenames and use the first one that exists
          if path = PathFinder.find(filename, paths)
            load_content(File.read(path), &block)
          end
        end
        
        def load_content(content, &block)
          YamlContext.render(content, &block)
        end
      end
      
      extend ClassMethods
    end
  end
end