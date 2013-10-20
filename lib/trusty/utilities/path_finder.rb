module Trusty
  module Utilities
    module PathFinder
      module ClassMethods
        def find(filename, paths = [])
          if File.exists? filename
            filename
          elsif root = paths.find{|path| File.exists?(File.join(path, filename))}
            File.join(root, filename)
          end
        end
      end
      
      extend ClassMethods
    end
  end
end