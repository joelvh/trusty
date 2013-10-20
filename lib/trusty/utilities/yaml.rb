module Trusty
  module Utilities
    module Yaml
      module ClassMethods
        def load_file(filename, paths = [])
          # allow multiple filenames and use the first one that exists
          if path = PathFinder.find(filename, paths)
            source = File.read(path)
            source = ERB.new(source).result
            
            YAML.load(source)
          end
        end
      end
      
      extend ClassMethods
    end
  end
end